#!/bin/bash

# Configuration
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
REPO_NAME="runwar"
FRONTEND_IMAGE_NAME="runwar-frontend"
BACKEND_SERVICE_NAME="runwar-backend"

echo "Using Project ID: $PROJECT_ID"

# 1. Get Backend URL
echo "Getting Backend URL..."
BACKEND_URL=$(gcloud run services describe $BACKEND_SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)' 2>/dev/null)

if [ -z "$BACKEND_URL" ]; then
    echo "Could not automatically detect Backend URL."
    echo "Please enter the Backend URL (e.g., https://runwar-backend-xyz.a.run.app):"
    read BACKEND_URL
else
    echo "Auto-detected Backend URL: $BACKEND_URL"
fi

# 2. Get Mapbox Token
if [ -z "$NEXT_PUBLIC_MAPBOX_TOKEN" ]; then
    # Try to read from .env.local if exists
    ENV_FILE="../frontend/.env.local"
    if [ -f "$ENV_FILE" ]; then
        DETECTED_TOKEN=$(grep NEXT_PUBLIC_MAPBOX_TOKEN $ENV_FILE | cut -d '=' -f2)
    fi

    if [ -n "$DETECTED_TOKEN" ]; then
        echo "Found Mapbox token in .env.local: ${DETECTED_TOKEN:0:10}..."
        echo "Use this token? (y/n)"
        read USE_TOKEN
        if [ "$USE_TOKEN" = "y" ]; then
            NEXT_PUBLIC_MAPBOX_TOKEN=$DETECTED_TOKEN
        fi
    fi
fi

if [ -z "$NEXT_PUBLIC_MAPBOX_TOKEN" ]; then
    echo "Please enter your Mapbox Public Token:"
    read NEXT_PUBLIC_MAPBOX_TOKEN
fi

echo "------------------------------------------------"
echo "Rebuilding and Deploying Frontend"
echo "Backend URL: $BACKEND_URL"
echo "Mapbox Token: ${NEXT_PUBLIC_MAPBOX_TOKEN:0:10}..."
echo "------------------------------------------------"

# 3. Build Frontend Image with Build Args
echo "Building Frontend image (this may take a few minutes)..."
# Create temp cloudbuild.yaml
cat > frontend/cloudbuild.yaml <<EOF
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: [ 'build', '-t', '\$_IMAGE_NAME', '--build-arg', 'NEXT_PUBLIC_API_URL=\$_NEXT_PUBLIC_API_URL', '--build-arg', 'NEXT_PUBLIC_MAPBOX_TOKEN=\$_NEXT_PUBLIC_MAPBOX_TOKEN', '.' ]
images:
- '\$_IMAGE_NAME'
EOF

gcloud builds submit frontend \
    --config frontend/cloudbuild.yaml \
    --substitutions _IMAGE_NAME="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$FRONTEND_IMAGE_NAME:latest",_NEXT_PUBLIC_API_URL="$BACKEND_URL",_NEXT_PUBLIC_MAPBOX_TOKEN="$NEXT_PUBLIC_MAPBOX_TOKEN"

rm frontend/cloudbuild.yaml


# 4. Deploy to Cloud Run
echo "Deploying Frontend to Cloud Run..."
gcloud run deploy $FRONTEND_IMAGE_NAME \
    --image "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$FRONTEND_IMAGE_NAME:latest" \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --cpu=1 \
    --memory=512Mi \
    --min-instances=0 \
    --max-instances=1

# Get the Frontned URL
FRONTEND_URL=$(gcloud run services describe $FRONTEND_IMAGE_NAME --platform managed --region $REGION --format 'value(status.url)')

echo ""
echo "------------------------------------------------"
echo "FRONTEND DEPLOYED SUCCESSFULLY"
echo "App URL: $FRONTEND_URL"
echo "------------------------------------------------"

# 5. Update Backend CORS
echo ""
echo "------------------------------------------------"
echo "Updating Backend CORS Configuration"
echo "------------------------------------------------"

echo "Updating $BACKEND_SERVICE_NAME to allow requests from $FRONTEND_URL..."
# Note: This updates the CORS_ORIGINS environment variable on the backend service
gcloud run services update $BACKEND_SERVICE_NAME \
    --region $REGION \
    --platform managed \
    --update-env-vars CORS_ORIGINS=$FRONTEND_URL

echo "Backend CORS updated successfully!"

echo "Done! RunWar is live."
