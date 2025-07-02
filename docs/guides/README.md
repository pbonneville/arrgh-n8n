# n8n Cloud Run Migration Guides

This directory contains comprehensive guides for migrating n8n from Render.com to Google Cloud Run.

## Migration Documentation

### 📋 Planning & Execution
- **`CLOUD-RUN-MIGRATION.md`** - Complete migration guide with step-by-step instructions
- **`migration-success.md`** - Post-migration summary and success report

### ⚙️ Configuration Management
- **`CONFIGURATION-GUIDE.md`** - Environment variables and template configuration guide

### 🌐 Domain Configuration  
- **`DNS-UPDATE-GUIDE.md`** - Instructions for updating DNS records to point to Cloud Run

## Migration Overview

The migration successfully moved n8n from Render.com to Google Cloud Run with:

### ✅ Completed
- **Infrastructure**: Cloud Run, Artifact Registry, Secret Manager
- **Database**: Preserved existing Cloud SQL PostgreSQL 
- **Security**: All credentials migrated to Secret Manager
- **Domain**: Custom domain `n8n.paulbonneville.com` configured
- **Version**: Updated to n8n v1.98.1 (latest)
- **Workflows**: Imported via API

### 💰 Cost Optimization
- **Removed**: Unnecessary VPC connector (saved ~$518/month)
- **Deleted**: Unused Cloud SQL instance (saved ~$35/month)
- **Total Savings**: ~$553/month
- **New Cost**: ~$30-55/month (vs ~$583-608/month previously)

### 📊 Performance Benefits
- **Scaling**: Auto-scaling from 1-10 instances
- **Resources**: 2 CPU, 2GB RAM with always-allocated CPU
- **SSL**: Automatic HTTPS with Google-managed certificates
- **Monitoring**: Integrated Cloud Run monitoring and logging

## Key Files Referenced

- `/scripts/` - All automation scripts
- `cloud-run-deployment.template.yaml` - Template for Cloud Run service configuration
- `cloud-run-deployment.yaml` - Generated Cloud Run service configuration
- `Dockerfile.cloudrun` - Cloud Run optimized container
- `.env.example` - Environment variables template
- `config/environments/` - Environment-specific configuration files

## Support

For issues or questions about the migration:
1. Check the relevant guide in this directory
2. Review Cloud Run logs: `gcloud run logs read --service=n8n-app`
3. Verify service status: `gcloud run services describe n8n-app`

---

**Migration Date**: July 2, 2025  
**Status**: ✅ Complete and Operational  
**URL**: https://n8n.paulbonneville.com