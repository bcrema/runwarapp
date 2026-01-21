#!/bin/bash

# Configuration
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
REPO_NAME="runwar"
BACKEND_IMAGE_NAME="runwar-backend"
DB_INSTANCE_NAME="runwar-db"
DB_NAME="runwar"
DB_USER="runwar-user"

echo "Using Project ID: $PROJECT_ID"

# Check if DB password is provided or stored
if [ -z "$DB_PASSWORD" ]; then
    echo "Please enter the database password (from setup-db.sh output):"
    read -s DB_PASSWORD
fi

# Check if JWT Secret is provided
if [ -z "$JWT_SECRET" ]; then
    echo "Generating a random JWT secret..."
    JWT_SECRET=$(openssl rand -base64 32)
fi

# Get Cloud SQL Connection Name
echo "Getting Cloud SQL connection name..."
DB_CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE_NAME --format="value(connectionName)")
echo "Connection Name: $DB_CONNECTION_NAME"

# Deploy to Cloud Run
echo "Deploying Backend to Cloud Run..."
gcloud run deploy $BACKEND_IMAGE_NAME \
    --image "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$BACKEND_IMAGE_NAME:latest" \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --add-cloudsql-instances $DB_CONNECTION_NAME \
    --set-env-vars "SPRING_PROFILES_ACTIVE=prod" \
    --set-env-vars "DATABASE_URL=jdbc:postgresql:///$DB_NAME?socketFactory=com.google.cloud.sql.postgres.SocketFactory&cloudSqlInstance=$DB_CONNECTION_NAME" \
    --set-env-vars "DATABASE_USER=$DB_USER" \
    --set-env-vars "DATABASE_PASSWORD=$DB_PASSWORD" \
    --set-env-vars "JWT_SECRET=$JWT_SECRET" \
    --cpu=1 \
    --memory=512Mi \
    --min-instances=0 \
    --max-instances=1

# Get the URL
BACKEND_URL=$(gcloud run services describe $BACKEND_IMAGE_NAME --platform managed --region $REGION --format 'value(status.url)')

echo "------------------------------------------------"
echo "BACKEND DEPLOYED SUCCESSFULLY"
echo "URL: $BACKEND_URL"
echo "------------------------------------------------"
echo ""
echo "NEXT STEPS:"
echo "1. Run './scripts/deploy-frontend.sh' to build and deploy the frontend."
