# Render Deployment Guide

This directory contains the configuration files for deploying n8n to Render.com as a cost-effective alternative to GKE, using your existing Cloud SQL database.

## Files Overview

- `render.yaml` - Render blueprint defining n8n service and Cloud SQL connection
- `n8n/Dockerfile` - n8n application container configuration

## Deployment Steps

1. **Prepare Repository**
   - Ensure all files are committed to your Git repository
   - Push to GitHub (Render connects via GitHub integration)

2. **Create Render Account**
   - Sign up at [render.com](https://render.com)
   - Connect your GitHub account

3. **Deploy via Blueprint**
   - In Render dashboard, click "New" → "Blueprint"
   - Select your repository
   - Render will automatically detect `render.yaml`
   - Review the configuration and click "Apply"

4. **Configure Manual Environment Variables**
   Before deployment, set these secrets in Render dashboard:
   - `DB_POSTGRESDB_PASSWORD` - Your Cloud SQL postgres password
   - `N8N_SMTP_USER` - AWS SES SMTP username
   - `N8N_SMTP_PASS` - AWS SES SMTP password

5. **Monitor Deployment**
   - Watch the build logs for the n8n service
   - Service will connect to existing Cloud SQL database
   - Check logs for successful database connection

6. **Access n8n**
   - Navigate to the auto-assigned URL (e.g., `https://n8n-arrgh.onrender.com`)
   - Login with username `admin` and the auto-generated password
   - Find the password in Render dashboard under service environment variables

## Expected Costs

- **Render Web Service**: ~$7/month
- **Database**: Uses existing Cloud SQL (no additional cost)
- **Total**: ~$7/month (significant savings compared to separate database)
- **Includes**: SSL certificates, custom domains, automatic deployments

## Configuration Notes

- **Database**: Uses existing Cloud SQL PostgreSQL at 35.225.58.181
- **Application**: 5GB persistent storage for n8n data
- **SSL**: Automatically provided by Render
- **Environment Variables**: Mix of auto-generated and manual secrets
- **Scaling**: Manual scaling available on paid plans
- **Network**: Ensure Cloud SQL allows connections from Render's IP ranges

## Cloud SQL Network Configuration

**Important**: Your Cloud SQL instance must allow connections from Render. You have two options:

### Option 1: Allow All IPs (Simple but less secure)
```bash
gcloud sql instances patch YOUR_INSTANCE_NAME --authorized-networks=0.0.0.0/0
```

### Option 2: Render-specific IPs (More secure)
Contact Render support for their current IP ranges and add them to your authorized networks.

## Troubleshooting

If deployment fails:

1. Check build logs in Render dashboard
2. Verify Cloud SQL connection and firewall rules
3. Ensure manual environment variables are set correctly
4. Test database connectivity from Render service
5. Verify SMTP credentials for email functionality

Common issues:
- **Database connection timeout**: Check Cloud SQL authorized networks
- **Authentication failed**: Verify `DB_POSTGRESDB_PASSWORD` is correct
- **Email not working**: Check AWS SES credentials and region

For n8n-specific issues, check the main project documentation in `../CLAUDE.md`.