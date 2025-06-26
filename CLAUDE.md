# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an n8n self-hosting setup supporting two deployment environments:
- **Local development**: Docker Compose with PostgreSQL
- **Production (Render)**: Render.com with Cloud SQL PostgreSQL (~$7/month cost-effective hosting)

The project uses Render.com as the production platform for its simplicity and cost-effectiveness.

## Architecture

### Dual Environment Design
- **Local**: `docker-compose.yml` provides isolated development with bundled PostgreSQL
- **Production (Render)**: `render.yaml` blueprint deploys to Render.com with Cloud SQL database

### Configuration Strategy
- Local uses hardcoded credentials in docker-compose.yml
- Render uses environment variables with Cloud SQL database
- Both environments use the same n8n image (`n8nio/n8n:latest`)

### Database Architecture
- **Local**: PostgreSQL 14 container with persistent volumes
- **Production (Render)**: Cloud SQL PostgreSQL database (35.225.58.181)
- Configuration divergence handled through environment-specific files

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

### Render Production
```bash
# Deploy to Render (via Render dashboard or CLI)
# 1. Connect GitHub repository to Render
# 2. Create new Blueprint deployment using render.yaml
# 3. Render will automatically provision PostgreSQL and n8n services

# Monitor deployment status
render services list

# View service logs
render logs <service-id>

# Update environment variables
render env:set <service-id> KEY=value

# Scale services (if using paid plans)
render services scale <service-id> --replicas=2
```

## Key Configuration Points

### Render Configuration
Render deployment configured for cost-effectiveness (~$7/month):
- **Database**: Uses existing Cloud SQL PostgreSQL (35.225.58.181)
- **n8n Service**: Web service with persistent storage (5GB)
- **Auto-generated secrets**: Authentication and encryption keys
- **Manual secrets**: Database and SMTP credentials (set in dashboard)
- **Custom domain**: Configure via Render dashboard
- **SSL**: Automatically provisioned by Render

## Environment Access

### Local Access
- URL: http://localhost:5678
- Username: `admin`
- Password: `password`

### Production Access (Render)
- URL: Automatically assigned by Render (e.g., `https://n8n-arrgh.onrender.com`)
- Username: `admin`
- Password: Check Render dashboard for auto-generated password

## Troubleshooting Context

### Common Local Issues
- Port 5678 conflicts: Modify `docker-compose.yml` ports section
- Database connectivity: Ensure PostgreSQL container is healthy

### Common Render Issues
- Service startup failures: Check service logs in Render dashboard
- Database connection errors: Verify Cloud SQL connectivity and firewall rules
- Build failures: Ensure Dockerfile paths are correct in render.yaml
- Environment variable issues: Check auto-generated values in dashboard

## Cost Considerations

**Render deployment** cost-effective hosting solution:
- Estimated $7/month for starter plan (web service only)
- Uses existing Cloud SQL database
- No additional database costs
- No infrastructure management required

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