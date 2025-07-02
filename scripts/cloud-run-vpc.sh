#!/bin/bash

# VPC Connector Setup for Cloud Run to Cloud SQL connectivity
# This script creates a VPC connector for secure database access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🌐 Setting up VPC Connector for Cloud Run${NC}"
echo "============================================="

# Get current project and region
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
REGION=${REGION:-us-central1}

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ No Google Cloud project set. Please run the setup script first.${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Using project: ${PROJECT_ID}${NC}"
echo -e "${GREEN}🌍 Using region: ${REGION}${NC}"
echo ""

# VPC Connector configuration
CONNECTOR_NAME="n8n-vpc-connector"
SUBNET_RANGE="10.8.0.0/28"  # Small subnet for the connector

echo -e "${YELLOW}Step 1: Creating VPC connector...${NC}"

# Check if connector already exists
if gcloud compute networks vpc-access connectors describe "$CONNECTOR_NAME" \
   --region="$REGION" --project="$PROJECT_ID" &>/dev/null; then
    echo -e "${YELLOW}ℹ️  VPC connector already exists: $CONNECTOR_NAME${NC}"
    
    # Show connector details
    gcloud compute networks vpc-access connectors describe "$CONNECTOR_NAME" \
        --region="$REGION" --project="$PROJECT_ID" \
        --format="table(name,network,ipCidrRange,state)"
else
    echo "Creating VPC connector: $CONNECTOR_NAME"
    
    # Create VPC connector
    gcloud compute networks vpc-access connectors create "$CONNECTOR_NAME" \
        --network="default" \
        --range="$SUBNET_RANGE" \
        --region="$REGION" \
        --project="$PROJECT_ID"
    
    echo -e "${GREEN}✅ VPC connector created successfully${NC}"
fi

echo ""
echo -e "${YELLOW}Step 2: Verifying Cloud SQL connectivity...${NC}"

# Get Cloud SQL instance info from .env file
if [ -f ".env" ]; then
    DB_HOST=$(grep "^DB_POSTGRESDB_HOST=" .env | cut -d'=' -f2 | sed 's/^"//' | sed 's/"$//')
    
    if [ -n "$DB_HOST" ]; then
        echo "Database host: $DB_HOST"
        
        # Check if this is a private IP (starts with 10., 172.16-31., or 192.168.)
        if [[ $DB_HOST =~ ^10\. ]] || [[ $DB_HOST =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || [[ $DB_HOST =~ ^192\.168\. ]]; then
            echo -e "${GREEN}✅ Database uses private IP - VPC connector required${NC}"
        else
            echo -e "${YELLOW}ℹ️  Database uses public IP - VPC connector optional but recommended${NC}"
        fi
        
        # Test if we can resolve the IP
        if nslookup "$DB_HOST" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Database host resolves correctly${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not resolve database host (this may be normal for private IPs)${NC}"
        fi
    else
        echo -e "${RED}❌ Could not find database host in .env file${NC}"
    fi
else
    echo -e "${RED}❌ .env file not found${NC}"
fi

echo ""
echo -e "${YELLOW}Step 3: Updating deployment configuration...${NC}"

# Update the deployment YAML with actual project details
if [ -f "cloud-run-deployment.yaml" ]; then
    # Create a backup
    cp cloud-run-deployment.yaml cloud-run-deployment.yaml.bak
    
    # Replace placeholders with actual values
    sed -i.tmp "s/PROJECT_ID/$PROJECT_ID/g" cloud-run-deployment.yaml
    sed -i.tmp "s/REGION/$REGION/g" cloud-run-deployment.yaml
    rm cloud-run-deployment.yaml.tmp 2>/dev/null || true
    
    echo -e "${GREEN}✅ Deployment configuration updated${NC}"
else
    echo -e "${RED}❌ cloud-run-deployment.yaml not found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 VPC setup complete!${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "VPC Connector: $CONNECTOR_NAME"
echo "Region: $REGION"
echo "Subnet Range: $SUBNET_RANGE"
echo "Full Connector Name: projects/$PROJECT_ID/locations/$REGION/connectors/$CONNECTOR_NAME"

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Build your Docker image: docker build -f Dockerfile.cloudrun -t n8n-cloudrun ."
echo "2. Push to Artifact Registry"
echo "3. Deploy to Cloud Run"