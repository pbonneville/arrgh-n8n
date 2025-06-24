# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an n8n self-hosting setup supporting two deployment environments:
- **Local development**: Docker Compose with PostgreSQL
- **Production**: Google Kubernetes Engine (GKE) Autopilot with Supabase

The project transitioned from Cloud Run (due to n8n initialization issues) to GKE for better compatibility.

## Architecture

### Dual Environment Design
- **Local**: `docker-compose.yml` provides isolated development with bundled PostgreSQL
- **Production**: Kubernetes manifests in `kubernetes/` directory deploy to GKE with external Supabase database

### Configuration Strategy
- Local uses hardcoded credentials in docker-compose.yml
- GKE uses ConfigMap/Secret pattern separating config from sensitive data
- Both environments use the same n8n image (`n8nio/n8n:latest`)

### Database Architecture
- **Local**: PostgreSQL 14 container with persistent volumes
- **Production**: External Supabase PostgreSQL with SSL connection
- Configuration divergence handled through environment-specific manifests

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

### GKE Production
```bash
# Create cluster
gcloud container clusters create-auto n8n-cluster --region=us-central1 --release-channel=regular

# Connect to cluster
gcloud container clusters get-credentials n8n-cluster --region=us-central1

# Deploy all manifests
kubectl apply -f kubernetes/

# Check deployment status
kubectl get pods -n n8n
kubectl get service n8n-service -n n8n

# View logs
kubectl logs -n n8n -l app=n8n

# Scale deployment
kubectl scale deployment/n8n --replicas=0 -n n8n  # Stop
kubectl scale deployment/n8n --replicas=1 -n n8n  # Start

# Update n8n version
kubectl set image deployment/n8n n8n=n8nio/n8n:new-version -n n8n
```

## Key Configuration Points

### Kubernetes Secrets Management
Before deploying to GKE, update `kubernetes/secrets.yaml`:
- `N8N_BASIC_AUTH_PASSWORD`: Web interface password
- `N8N_ENCRYPTION_KEY`: For credential encryption
- `DB_POSTGRESDB_PASSWORD`: Supabase database password

### Database Connection Configuration
Edit `kubernetes/configmap.yaml` for Supabase connection:
- `DB_POSTGRESDB_HOST`: Your Supabase host (format: db.xxxxx.supabase.co)
- Database remains `postgres` with user `postgres` on port `5432`

### Resource Limits
GKE deployment configured for minimal cost:
- 1 CPU, 2GB memory requests/limits
- Single replica sufficient for personal use
- Session affinity enabled for webhook consistency

## Environment Access

### Local Access
- URL: http://localhost:5678
- Username: `admin`
- Password: `password`

### Production Access
- Get external IP: `kubectl get service n8n-service -n n8n`
- URL: `http://<EXTERNAL-IP>`
- Credentials: Set in `kubernetes/secrets.yaml`

## Troubleshooting Context

### Common Local Issues
- Port 5678 conflicts: Modify `docker-compose.yml` ports section
- Database connectivity: Ensure PostgreSQL container is healthy

### Common GKE Issues
- Pod startup failures: Check logs and verify Supabase credentials
- No external IP: Verify GKE LoadBalancer permissions
- Database timeouts: Confirm Supabase firewall allows connections

### Health Check Configuration
GKE deployment includes health checks on `/healthz` endpoint with extended timeouts to accommodate n8n's initialization process (120s initial delay for liveness probe).

## Cost Considerations

GKE deployment optimized for free tier usage:
- Estimated $0-40/month with free tier credits
- Single minimal resource allocation
- Alternative platforms (Railway, Render) available if costs exceed budget

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