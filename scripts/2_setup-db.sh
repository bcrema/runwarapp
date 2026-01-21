#!/bin/bash

# Configuration
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1" # Change this if needed

# Database Configuration
DB_INSTANCE_NAME="runwar-db"
DB_NAME="runwar"
DB_USER="runwar-user"
# Generate a random password for new instances
DB_PASSWORD=$(openssl rand -base64 16)

echo "Using Project ID: $PROJECT_ID"

echo "------------------------------------------------"
echo "Cloud SQL Setup"
echo "------------------------------------------------"

# Check if instance exists
EXISTING_INSTANCE=$(gcloud sql instances list --format="value(name)" --filter="name:$DB_INSTANCE_NAME")

if [ -n "$EXISTING_INSTANCE" ]; then
    echo "Cloud SQL instance '$DB_INSTANCE_NAME' already exists."
else
    echo "Creating Cloud SQL instance '$DB_INSTANCE_NAME' (this may take 10-15 minutes)..."
    
    # Create instance
    gcloud sql instances create $DB_INSTANCE_NAME \
        --database-version=POSTGRES_15 \
        --tier=db-f1-micro \
        --region=$REGION \
        --project=$PROJECT_ID \
        --storage-type=HDD \
        --storage-size=10GB \
        --root-password=$DB_PASSWORD 

    echo "Creating database '$DB_NAME'..."
    gcloud sql databases create $DB_NAME --instance=$DB_INSTANCE_NAME

    echo "Creating user '$DB_USER'..."
    gcloud sql users create $DB_USER \
        --instance=$DB_INSTANCE_NAME \
        --password=$DB_PASSWORD

    echo "------------------------------------------------"
    echo "CLOUD SQL CREATED SUCCESSFULLY"
    echo "Instance: $DB_INSTANCE_NAME"
    echo "Database: $DB_NAME"
    echo "User:     $DB_USER"
    echo "Password: $DB_PASSWORD"
    echo "------------------------------------------------"
    echo "IMPORTANT: Save these credentials! You will need them for the next step."
fi
