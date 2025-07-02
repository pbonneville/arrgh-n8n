#!/bin/bash

# Configuration Generator for n8n Cloud Run Deployment
# This script generates final configuration files from templates using environment variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}⚙️  Generating n8n Configuration Files${NC}"
echo "==========================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if envsubst is available
if ! command_exists envsubst; then
    echo -e "${RED}❌ envsubst not found. Please install gettext package.${NC}"
    echo "On macOS: brew install gettext"
    echo "On Ubuntu/Debian: apt-get install gettext-base"
    exit 1
fi

# Load environment variables
ENV_FILE=".env"
if [ -n "$1" ]; then
    ENV_FILE="$1"
fi

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Environment file not found: $ENV_FILE${NC}"
    echo "Available options:"
    echo "  - .env (default)"
    echo "  - config/environments/production.env"
    echo "  - config/environments/development.env"
    exit 1
fi

echo -e "${BLUE}📁 Loading environment from: $ENV_FILE${NC}"
export $(grep -v '^#' "$ENV_FILE" | xargs)

# Validate required variables
REQUIRED_VARS=("PROJECT_ID" "REGION" "REPO_NAME" "SERVICE_NAME")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please check your $ENV_FILE file or use .env.example as a template."
    exit 1
fi

echo -e "${GREEN}✅ Environment variables loaded successfully${NC}"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Repository: $REPO_NAME"
echo "Service: $SERVICE_NAME"
echo ""

# Generate deployment configuration
echo -e "${YELLOW}Step 1: Generating Cloud Run deployment configuration...${NC}"

if [ ! -f "cloud-run-deployment.template.yaml" ]; then
    echo -e "${RED}❌ Template file not found: cloud-run-deployment.template.yaml${NC}"
    exit 1
fi

envsubst < cloud-run-deployment.template.yaml > cloud-run-deployment-generated.yaml
echo -e "${GREEN}✅ Generated: cloud-run-deployment-generated.yaml${NC}"

# Validate generated YAML
echo -e "${YELLOW}Step 2: Validating generated configuration...${NC}"

# Check if gcloud is available for validation
if command_exists gcloud; then
    # Basic YAML syntax check
    if python3 -c "import yaml; yaml.safe_load(open('cloud-run-deployment-generated.yaml'))" 2>/dev/null; then
        echo -e "${GREEN}✅ YAML syntax validation passed${NC}"
    else
        echo -e "${YELLOW}⚠️  YAML syntax validation failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  gcloud not found, skipping validation${NC}"
fi

# Generate environment summary
echo -e "${YELLOW}Step 3: Generating deployment summary...${NC}"

cat > deployment-summary.txt << EOF
n8n Cloud Run Deployment Summary
===============================

Generated on: $(date)
Environment file: $ENV_FILE

Configuration:
- Project ID: $PROJECT_ID
- Region: $REGION
- Repository: $REPO_NAME
- Service Name: $SERVICE_NAME
- Image: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/n8n:latest
- Service Account: n8n-cloud-run-sa@$PROJECT_ID.iam.gserviceaccount.com

Generated Files:
- cloud-run-deployment-generated.yaml

Next Steps:
1. Review the generated configuration
2. Deploy using: ./scripts/cloud-run-deploy.sh
3. Configure custom domain if needed
EOF

echo -e "${GREEN}✅ Generated: deployment-summary.txt${NC}"

echo ""
echo -e "${GREEN}🎉 Configuration generation complete!${NC}"
echo ""
echo -e "${BLUE}Generated files:${NC}"
echo "  - cloud-run-deployment-generated.yaml"
echo "  - deployment-summary.txt"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the generated configuration"
echo "2. Deploy with: ./scripts/cloud-run-deploy.sh"
echo "3. Configure secrets: ./scripts/cloud-run-secrets.sh (if not done)"
echo ""