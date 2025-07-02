#!/bin/bash

# Google Cloud Secret Manager Setup for n8n
# This script migrates .env variables to Google Cloud Secret Manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Setting up Google Cloud Secrets${NC}"
echo "======================================"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found. Please ensure you have your environment variables configured.${NC}"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ No Google Cloud project set. Please run the setup script first.${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Using project: ${PROJECT_ID}${NC}"
echo ""

# Function to create secret from .env file
create_secret() {
    local secret_name=$1
    local env_var=$2
    
    # Extract value from .env file
    local value=$(grep "^${env_var}=" .env | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
    
    if [ -n "$value" ]; then
        echo "Creating secret: $secret_name"
        
        # Check if secret already exists
        if gcloud secrets describe "$secret_name" --project="$PROJECT_ID" &>/dev/null; then
            echo -e "${YELLOW}ℹ️  Secret $secret_name already exists, creating new version...${NC}"
            echo -n "$value" | gcloud secrets versions add "$secret_name" --data-file=- --project="$PROJECT_ID"
        else
            echo -n "$value" | gcloud secrets create "$secret_name" --data-file=- --project="$PROJECT_ID"
        fi
        
        echo -e "${GREEN}✅ Secret created: $secret_name${NC}"
    else
        echo -e "${YELLOW}⚠️  Warning: $env_var not found in .env file${NC}"
    fi
}

echo -e "${YELLOW}Creating secrets from .env file...${NC}"
echo ""

# Database secrets
create_secret "n8n-db-host" "DB_POSTGRESDB_HOST"
create_secret "n8n-db-database" "DB_POSTGRESDB_DATABASE"
create_secret "n8n-db-user" "DB_POSTGRESDB_USER"
create_secret "n8n-db-password" "DB_POSTGRESDB_PASSWORD"

# n8n configuration secrets
create_secret "n8n-encryption-key" "N8N_ENCRYPTION_KEY"
create_secret "n8n-api-key" "N8N_API_KEY"

# AWS SES email secrets
create_secret "n8n-smtp-host" "N8N_SMTP_HOST"
create_secret "n8n-smtp-user" "N8N_SMTP_USER"
create_secret "n8n-smtp-pass" "N8N_SMTP_PASS"
create_secret "n8n-default-email" "N8N_DEFAULT_EMAIL"
create_secret "n8n-smtp-sender" "N8N_SMTP_SENDER"

# API keys
create_secret "anthropic-api-key" "ANTHROPIC_API_KEY"
create_secret "aws-access-key-id" "AWS_ACCESS_KEY_ID"
create_secret "aws-secret-access-key" "AWS_SECRET_ACCESS_KEY"

echo ""
echo -e "${GREEN}🎉 Secrets setup complete!${NC}"
echo ""
echo -e "${YELLOW}Created secrets:${NC}"
gcloud secrets list --project="$PROJECT_ID" --filter="name~n8n OR name~anthropic OR name~aws" --format="table(name)"

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Build your Docker image with: docker build -t n8n-cloudrun ."
echo "2. Push to Artifact Registry"
echo "3. Deploy to Cloud Run"