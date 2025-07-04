# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an n8n self-hosting setup supporting two deployment environments:
- **Local development**: Docker Compose with PostgreSQL
- **Production (Google Cloud Run)**: Google Cloud Run with Cloud SQL PostgreSQL (~$50/month optimized hosting)

The project uses Google Cloud Run as the production platform for its scalability, cost optimization, and enterprise features.

## Architecture

### Dual Environment Design
- **Local**: `docker-compose.yml` provides isolated development with bundled PostgreSQL
- **Production (Google Cloud Run)**: `cloud-run-deployment.yaml` deploys to Google Cloud Run with Cloud SQL database

### Configuration Strategy
- Local uses hardcoded credentials in docker-compose.yml
- Google Cloud Run uses environment variables with Cloud SQL database and Google Secret Manager
- Both environments use the same n8n image (`n8nio/n8n:latest`)

### Database Architecture
- **Local**: PostgreSQL 14 container with persistent volumes
- **Production (Google Cloud Run)**: Cloud SQL PostgreSQL database (connection via Cloud SQL Auth Proxy)
- Configuration divergence handled through environment-specific files and templates

## Common Commands

### Local Development
```bash
# Start n8n with database
docker-compose up -d

# View logs
docker-compose logs -f n8n

# Stop and preserve data
docker-compose down

# Stop and remove all data
docker-compose down -v

# Restart n8n service only
docker-compose restart n8n
```

### Google Cloud Run Production
```bash
# Deploy to Google Cloud Run
./scripts/cloud-run-deploy.sh

# Monitor deployment status
gcloud run services list --region=us-central1

# View service logs
gcloud run logs read --service=n8n-app --region=us-central1

# Update environment variables
gcloud run services update n8n-app --region=us-central1 --set-env-vars="KEY=value"

# Scale services (auto-scaling configured)
gcloud run services update n8n-app --region=us-central1 --max-instances=10 --min-instances=1
```

## Key Configuration Points

### Google Cloud Run Configuration
Google Cloud Run deployment configured for cost optimization (~$50/month):
- **Database**: Uses existing Cloud SQL PostgreSQL (35.225.58.181)
- **n8n Service**: Cloud Run service with auto-scaling (1-10 instances)
- **Resource allocation**: 2 CPU, 2GB RAM per instance
- **Secrets**: Stored in Google Secret Manager
- **Custom domain**: Configure via Cloud Run domain mappings
- **SSL**: Automatically provisioned by Google

## Environment Access

### Local Access
- URL: http://localhost:5678
- Username: `admin`
- Password: `password`

### Production Access (Google Cloud Run)
- URL: https://n8n.paulbonneville.com (custom domain) or Cloud Run assigned URL
- Username: `admin`
- Password: Check Google Secret Manager for `n8n-basic-auth-password`

## Troubleshooting Context

### Common Local Issues
- Port 5678 conflicts: Modify `docker-compose.yml` ports section
- Database connectivity: Ensure PostgreSQL container is healthy

### Common Google Cloud Run Issues
- Service startup failures: Check service logs with `gcloud run logs read --service=n8n-app`
- Database connection errors: Verify Cloud SQL connectivity and Secret Manager configuration
- Build failures: Ensure Docker image builds correctly for linux/amd64 platform
- Environment variable issues: Check Secret Manager values and service configuration

## Cost Considerations

**Google Cloud Run deployment** cost-optimized hosting solution:
- Estimated $50/month for production workload (reduced from $600/month)
- Uses existing Cloud SQL database
- Auto-scaling reduces costs during low usage
- No VPC connector costs (direct database connection)
- Enterprise features included (monitoring, logging, security)

## GitHub Actions & PR Standards

This repository uses shared GitHub Actions workflows from `arrgh-hub` for PR validation and automation:

### Workflow Architecture
- **Shared workflows**: Hosted in `pbonneville/arrgh-hub/.github/workflows/`
- **Local wrappers**: Minimal `.github/workflows/` files that call the shared ones
- **PR template**: Standardized `.github/pull_request_template.md`

### Features
- **PR Validation**: Size limits (200 lines for infra changes), conventional commits
- **Auto-labeling**: Based on PR type (feat, fix, docs, etc.)
- **Auto-merge**: Enabled for docs and chore PRs only
- **Release notes**: Automatic generation for features/fixes
- **Security scanning**: Detects security-related file changes

See `docs/github-actions-shared-workflows.md` for complete documentation.

## Inbound Email Processing

AWS SES inbound email processing is configured to forward emails to n8n for automated processing:

### Quick Deployment
```bash
# Deploy complete inbound email infrastructure
./deploy-inbound-email.sh
```

### Manual Setup
1. **Deploy AWS Infrastructure**: `cd terraform && terraform apply`
2. **Configure DNS**: Add MX record (see `docs/dns-mx-setup.md`)
3. **Import n8n Workflow**: Upload `workflows/inbound-email-processor.json`
4. **Test**: Send email to your domain

### Architecture
- **Email Reception**: AWS SES receives emails via MX record
- **Storage**: Emails stored in S3 bucket with 30-day lifecycle
- **Notification**: SNS triggers n8n webhook in real-time
- **Processing**: n8n downloads, parses, and processes email content
- **Custom Logic**: Add business logic in the "Process Email Logic" node

### Cost Impact
- SES: $0.10 per 1,000 emails received
- S3: Minimal storage costs (emails auto-deleted after 30 days)
- SNS: $0.50 per 1 million notifications

See `docs/inbound-email-deployment.md` for complete setup instructions.