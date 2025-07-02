#!/bin/bash

# Cloud Run Migration Setup Script for n8n
# This script sets up the Google Cloud infrastructure needed for n8n migration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 n8n Cloud Run Migration Setup${NC}"
echo "========================================"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI not found. Please install it first.${NC}"
    echo "Visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ No Google Cloud project set. Please run: gcloud config set project YOUR_PROJECT_ID${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Using project: ${PROJECT_ID}${NC}"

# Set default region (can be overridden)
REGION=${REGION:-us-central1}
echo -e "${GREEN}🌍 Using region: ${REGION}${NC}"

echo ""
echo -e "${YELLOW}Step 1: Enabling required APIs...${NC}"

# Enable required APIs
apis=(
    "artifactregistry.googleapis.com"
    "run.googleapis.com"
    "sqladmin.googleapis.com"
    "secretmanager.googleapis.com"
    "vpcaccess.googleapis.com"
    "compute.googleapis.com"
    "servicenetworking.googleapis.com"
)

for api in "${apis[@]}"; do
    echo "Enabling $api..."
    gcloud services enable "$api" --project="$PROJECT_ID"
done

echo -e "${GREEN}✅ APIs enabled successfully${NC}"
echo ""

echo -e "${YELLOW}Step 2: Creating Artifact Registry repository...${NC}"

# Create Artifact Registry repository
REPO_NAME="n8n-repo"
if ! gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" --project="$PROJECT_ID" &>/dev/null; then
    gcloud artifacts repositories create "$REPO_NAME" \
        --repository-format=docker \
        --location="$REGION" \
        --description="n8n Docker images for Cloud Run" \
        --project="$PROJECT_ID"
    echo -e "${GREEN}✅ Artifact Registry repository created: $REPO_NAME${NC}"
else
    echo -e "${YELLOW}ℹ️  Artifact Registry repository already exists: $REPO_NAME${NC}"
fi

echo ""
echo -e "${YELLOW}Step 3: Setting up authentication...${NC}"

# Configure Docker for Artifact Registry
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

echo -e "${GREEN}✅ Docker authentication configured${NC}"
echo ""

echo -e "${YELLOW}Step 4: Creating service account...${NC}"

# Create service account for Cloud Run
SERVICE_ACCOUNT="n8n-cloud-run-sa"
if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" --project="$PROJECT_ID" &>/dev/null; then
    gcloud iam service-accounts create "$SERVICE_ACCOUNT" \
        --description="Service account for n8n Cloud Run deployment" \
        --display-name="n8n Cloud Run Service Account" \
        --project="$PROJECT_ID"
    echo -e "${GREEN}✅ Service account created: $SERVICE_ACCOUNT${NC}"
else
    echo -e "${YELLOW}ℹ️  Service account already exists: $SERVICE_ACCOUNT${NC}"
fi

# Grant necessary permissions
echo "Granting IAM permissions..."
roles=(
    "roles/cloudsql.client"
    "roles/secretmanager.secretAccessor"
    "roles/storage.objectViewer"
)

for role in "${roles[@]}"; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="$role" \
        --quiet
done

echo -e "${GREEN}✅ IAM permissions granted${NC}"
echo ""

echo -e "${GREEN}🎉 Infrastructure setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run './cloud-run-secrets.sh' to set up Secret Manager"
echo "2. Build and deploy your n8n container"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Artifact Registry: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME"
echo "Service Account: $SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com"