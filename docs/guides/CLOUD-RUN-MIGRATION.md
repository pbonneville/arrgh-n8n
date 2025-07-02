# n8n Cloud Run Migration Guide

This guide walks you through migrating your n8n instance from Render.com to Google Cloud Run while preserving your existing Cloud SQL database.

## Migration Overview

**Current Setup:**
- Platform: Render.com (~$7/month)
- Database: Google Cloud SQL PostgreSQL
- Domain: [your-custom-domain.com]

**Target Setup:**
- Platform: Google Cloud Run
- Database: Same Cloud SQL instance (no migration needed)
- Enhanced: Secret Manager, Auto-scaling (VPC connector optional for public Cloud SQL)

## Prerequisites

1. **Google Cloud CLI installed and authenticated**
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Docker installed and running**

3. **Existing .env file with your credentials** (✅ Already present)

## Migration Steps

### Phase 1: Infrastructure Setup

Run the setup script to enable APIs and create core infrastructure:

```bash
./cloud-run-setup.sh
```

This script will:
- Enable required Google Cloud APIs
- Create Artifact Registry repository
- Set up service account with proper permissions
- Configure Docker authentication

### Phase 2: Secrets Configuration

Migrate your .env variables to Google Cloud Secret Manager:

```bash
./cloud-run-secrets.sh
```

This will create secrets for:
- Database credentials
- n8n encryption key and API key
- AWS SES email configuration
- Anthropic and AWS API keys

### Phase 3: VPC Connectivity

Set up VPC connector for secure database access:

```bash
./cloud-run-vpc.sh
```

This ensures secure connectivity between Cloud Run and your Cloud SQL database.

### Phase 4: Build and Deploy

Deploy your n8n instance to Cloud Run:

```bash
./cloud-run-deploy.sh
```

This script will:
- Build the Cloud Run-optimized Docker image
- Push to Artifact Registry
- Deploy to Cloud Run with all configurations
- Set up traffic routing and access policies

## Key Features

### Cloud Run Optimizations
- **Port Binding**: Automatically handles Cloud Run's dynamic PORT variable
- **Health Checks**: Built-in health monitoring at `/healthz`
- **Graceful Shutdown**: Proper signal handling for container lifecycle
- **Resource Limits**: Configured for optimal performance and cost

### Security Enhancements
- **Secret Manager**: All sensitive data stored securely
- **VPC Connector**: Private network access to database
- **Service Account**: Minimal permissions principle
- **SSL/TLS**: Automatic HTTPS termination

### Performance Features
- **Min Instances**: Configured to reduce cold starts
- **CPU Allocation**: Always-allocated CPU for consistent performance  
- **Memory Optimization**: 2GB memory limit for n8n workflows
- **Request Timeout**: 15-minute timeout for long-running workflows

## Post-Migration Tasks

### 1. Update Webhook URLs
Your new n8n instance will have a new URL. Update webhook URLs in:
- Existing n8n workflows
- External systems that call your webhooks
- DNS configuration (if using custom domain)

### 2. Test Integrations
Verify all integrations are working:
- AWS SES email functionality
- Database connectivity
- API integrations (Anthropic, etc.)
- Existing workflows

### 3. Configure Custom Domain
To use your existing domain `n8n.paulbonneville.com`:

```bash
# Map your domain to Cloud Run
gcloud run domain-mappings create \
  --service n8n-app \
  --domain n8n.paulbonneville.com \
  --region us-central1
```

Then update your DNS to point to the Cloud Run service.

## Cost Comparison

**Current (Render):** ~$7/month
**Expected (Cloud Run):** ~$5-15/month depending on usage

Cloud Run pricing is based on:
- CPU time: $0.00002400 per vCPU-second
- Memory: $0.00000250 per GiB-second  
- Requests: $0.40 per million requests

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Verify VPC connector is properly configured
   - Check Cloud SQL instance allows connections from Cloud Run
   - Validate database credentials in Secret Manager

2. **Cold Start Issues**
   - Increase minimum instances in deployment configuration
   - Monitor response times and adjust resources

3. **Secret Access Errors**
   - Verify service account has Secret Manager accessor role
   - Check secret names match deployment configuration

### Monitoring

- **Cloud Run Logs**: `gcloud logs read --filter="resource.type=cloud_run_revision"`
- **Service Metrics**: Check Cloud Run console for request patterns
- **Database Metrics**: Monitor Cloud SQL performance

## Rollback Plan

If needed, you can quickly rollback to Render:

1. Keep your Render service running during initial testing
2. Switch DNS back to Render URL
3. Your Cloud SQL database remains unchanged
4. Decommission Cloud Run resources if needed

## Files Created

- `cloud-run-setup.sh` - Initial infrastructure setup
- `cloud-run-secrets.sh` - Secret Manager configuration  
- `cloud-run-vpc.sh` - VPC connector setup
- `cloud-run-deploy.sh` - Build and deployment script
- `Dockerfile.cloudrun` - Cloud Run optimized container
- `cloud-run-startup.sh` - Container startup script
- `cloud-run-deployment.yaml` - Kubernetes service configuration

## Support

If you encounter issues:
1. Check the logs: `gcloud run logs read --service=n8n-app`
2. Verify secrets: `gcloud secrets list`
3. Test connectivity: Use Cloud Shell to test database connection
4. Review this guide and ensure all steps were completed

---

🚀 **Ready to migrate?** Start with `./cloud-run-setup.sh`