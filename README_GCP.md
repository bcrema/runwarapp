# GCP Deployment Guide for LigaRun

This project is set up to be deployed on **Google Cloud Run** using **Cloud SQL (PostgreSQL + PostGIS)**.

## 1. Prerequisites

- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated (`gcloud auth login`).
- A GCP Project created and billing enabled.
- Set your active project: `gcloud config set project [YOUR_PROJECT_ID]`.

## 2. Infrastructure Setup

### Cloud SQL (Database)

1.  Create a PostgreSQL instance:
    ```bash
    gcloud sql instances create runwar-db \
        --database-version=POSTGRES_15 \
        --tier=db-f1-micro \
        --region=us-central1 \
        --root-password=[YOUR_DB_PASSWORD]
    ```
2.  Enable PostGIS:
    Connect to your instance (e.g., via Cloud Shell or `gcloud sql connect`) and run:
    ```sql
    CREATE EXTENSION IF NOT EXISTS postgis;
    ```

### Artifact Registry

The deployment script handles this, but you can create it manually:
```bash
gcloud artifacts repositories create runwar --repository-format=docker --location=us-central1
```

## 3. Deployment Steps

### Step A: Build and Push Images

Run the provided script to build your containers using Cloud Build:
```bash
./scripts/gcp-deploy.sh
```

### Step B: Deploy Backend

Deploy the backend to Cloud Run. Replace placeholders with your actual values.

```bash
gcloud run deploy runwar-backend \
    --image us-central1-docker.pkg.dev/[PROJECT_ID]/runwar/runwar-backend:latest \
    --region us-central1 \
    --set-env-vars="DATABASE_URL=jdbc:postgresql:///[DB_NAME]?cloudSqlInstance=[PROJECT_ID]:us-central1:runwar-db&socketFactory=com.google.cloud.sql.postgres.SocketFactory" \
    --set-env-vars="DATABASE_USER=postgres" \
    --set-env-vars="DATABASE_PASSWORD=[YOUR_DB_PASSWORD]" \
    --set-env-vars="JWT_SECRET=[YOUR_JWT_SECRET]" \
    --add-cloudsql-instances [PROJECT_ID]:us-central1:runwar-db \
    --allow-unauthenticated
```
*Note the backend URL provided after deployment.*

### Step C: Deploy Frontend

Deploy the frontend, passing the backend URL as an environment variable.

```bash
gcloud run deploy runwar-frontend \
    --image us-central1-docker.pkg.dev/[PROJECT_ID]/runwar/runwar-frontend:latest \
    --region us-central1 \
    --set-env-vars="NEXT_PUBLIC_API_URL=[BACKEND_URL]" \
    --allow-unauthenticated
```

## 4. CI/CD (Optional)

You can set up GitHub Actions to run these steps automatically on every push to `master`.
Check `.github/workflows/deploy.yml` for an example (if created).
