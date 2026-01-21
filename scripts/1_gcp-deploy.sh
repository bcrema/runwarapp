#!/bin/bash

# Configuration
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1" # Change this if needed
REPO_NAME="runwar"
BACKEND_IMAGE_NAME="runwar-backend"

echo "Using Project ID: $PROJECT_ID"

# 1. Enable APIs
echo "Enabling necessary APIs..."
gcloud services enable \
    artifactregistry.googleapis.com \
    run.googleapis.com \
    sqladmin.googleapis.com \
    cloudbuild.googleapis.com

# 2. Create Artifact Registry repository if it doesn't exist
echo "Checking Artifact Registry..."
gcloud artifacts repositories describe $REPO_NAME --location=$REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating Artifact Registry repository..."
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="RunWar Docker repository"
fi

# 3. Build and Push Backend Image using Cloud Build
echo "Building Backend image..."
gcloud builds submit backend \
    --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$BACKEND_IMAGE_NAME:latest"

echo "Builds complete!"
echo ""
echo "NEXT STEPS:"
echo "1. Run './scripts/2_setup-db.sh' to create the database if you haven't already."
echo "2. Run './scripts/3_deploy-backend.sh' to deploy the backend."
echo "3. Run './scripts/4_deploy-frontend.sh' to build and deploy the frontend."
