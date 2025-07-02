# Cloud Run Migration Scripts

This directory contains all the scripts created for migrating n8n from Render.com to Google Cloud Run.

## Scripts Overview

### Setup & Infrastructure
- **`cloud-run-setup.sh`** - Initial infrastructure setup (APIs, Artifact Registry, service accounts)
- **`cloud-run-secrets.sh`** - Migrates .env variables to Google Cloud Secret Manager
- **`cloud-run-vpc.sh`** - Sets up VPC connector (not needed for public Cloud SQL)

### Deployment
- **`cloud-run-deploy.sh`** - Complete build, push, and deployment script
- **`cloud-run-startup.sh`** - Container startup script (used inside Docker image)

### Monitoring
- **`monitor-domain.sh`** - Monitors domain migration from Render to Cloud Run

## Usage

### Initial Migration (One-time)
```bash
# 1. Set up infrastructure
./scripts/cloud-run-setup.sh

# 2. Create secrets
./scripts/cloud-run-secrets.sh

# 3. Deploy n8n
./scripts/cloud-run-deploy.sh
```

### Updates
```bash
# Rebuild and redeploy after changes
./scripts/cloud-run-deploy.sh
```

### Monitoring
```bash
# Watch domain migration progress
./scripts/monitor-domain.sh
```

## Notes

- All scripts are designed to be idempotent (safe to run multiple times)
- Scripts include error handling and status reporting
- The VPC script is included but not needed for public Cloud SQL instances
- Make sure you're authenticated with `gcloud auth login` before running

## File Permissions

All scripts should be executable:
```bash
chmod +x scripts/*.sh
```