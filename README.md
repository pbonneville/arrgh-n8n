# n8n Self-Hosted Setup

This repository provides configurations for running n8n both locally (for development) and on Render.com (for production).

## Overview

n8n is a workflow automation tool that allows you to connect various services and automate tasks. This setup includes:
- Local development environment with Docker Compose
- Production deployment on Render.com with Cloud SQL database
- Persistent storage for workflows and credentials

## Prerequisites

### Local Development
- Docker Desktop installed
- Docker Compose
- 4GB RAM available

### Production (Render)
- Render.com account
- GitHub repository connected to Render
- Render CLI installed (optional)
- Cloud SQL database (existing)

## Local Development

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd arrgh-n8n
   ```

2. **Start n8n locally**
   ```bash
   docker-compose up -d
   ```

3. **Access n8n**
   - URL: http://localhost:5678
   - Username: `admin`
   - Password: `password`

### Local Features
- PostgreSQL database included
- Data persists between restarts
- Suitable for development and testing
- No cloud costs

### Stopping Local Instance
```bash
docker-compose down
```

To remove all data:
```bash
docker-compose down -v
```

## Production Deployment (Render)

### Cost Estimate
- **Monthly cost**: ~$7 (web service only)
- Uses existing Cloud SQL database (no additional cost)
- Includes: SSL certificates, auto-deployments, monitoring

### Setup Steps

1. **Push Code to GitHub**
   ```bash
   git add .
   git commit -m "Add Render deployment configuration"
   git push origin main
   ```

2. **Deploy via Render Dashboard**
   - Login to [render.com](https://render.com)
   - Click "New" → "Blueprint"
   - Connect your GitHub repository
   - Render will detect `render.yaml` automatically
   - Click "Apply"

3. **Set Manual Environment Variables**
   In the Render dashboard, set these secrets:
   - `DB_POSTGRESDB_PASSWORD` - Your Cloud SQL postgres password
   - `N8N_SMTP_USER` - AWS SES SMTP username  
   - `N8N_SMTP_PASS` - AWS SES SMTP password

4. **Access n8n**
   - URL: Auto-assigned by Render (e.g., `https://n8n-yourapp.onrender.com`)
   - Username: `admin`
   - Password: Check Render dashboard for auto-generated password

### Production Features
- Persistent storage via Cloud SQL
- Automatic SSL certificates
- Auto-deployments from GitHub
- Built-in monitoring and logging
- Custom domain support

### Monitoring

View service status:
```bash
render services list --output json
```

View logs:
```bash
render logs <service-id>
```

### Updating n8n

Render automatically deploys when you push to GitHub:
```bash
git push origin main
```

Or manually trigger a deploy in the Render dashboard.

## Project Structure

```
arrgh-n8n/
├── docker-compose.yml     # Local development setup
├── render.yaml           # Render deployment blueprint
├── render/               # Render deployment files
│   ├── n8n/
│   │   └── Dockerfile    # n8n container configuration
│   └── README.md         # Render deployment guide
├── README.md            # This file
├── CLAUDE.md            # Claude Code project instructions
└── .gitignore          # Git ignore rules
```

## Database Configuration

This setup uses Cloud SQL for the production database:
- **Why Cloud SQL**: Managed PostgreSQL, reliable, shared with other services
- **Connection**: Direct connection on port 5432 at 35.225.58.181
- **Access**: Configured to allow connections from Render

## Security Considerations

1. **Change default passwords** in both local and production
2. **Use strong encryption keys** for credentials
3. **Enable SSL** in production (add Ingress with cert-manager)
4. **Regular backups** of your Supabase database
5. **Keep n8n updated** for security patches

## Troubleshooting

### Local Issues
- **Port 5678 in use**: Change port in docker-compose.yml
- **Database connection failed**: Ensure PostgreSQL container is running

### Render Issues
- **Service not starting**: Check logs in Render dashboard
- **Database connection failed**: Verify Cloud SQL firewall rules and credentials
- **Build failures**: Check Dockerfile paths in render.yaml

### Common Commands

```bash
# Local
docker-compose logs -f n8n    # View logs
docker-compose restart n8n    # Restart n8n

# Render
render services list          # List all services
render logs <service-id>      # View service logs
```

## Cost Optimization

1. **Use Render Starter plan** - $7/month for web service
2. **Shared database** - No additional database costs
3. **Auto-scaling disabled** - Keep costs predictable
4. **Consider free tier** for small workloads

## Next Steps

1. **Add custom domain** via Render dashboard
2. **HTTPS is automatic** - SSL certificates included
3. **Set up monitoring** with Render's built-in tools
4. **Configure webhooks** for workflow automation

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Render Documentation](https://render.com/docs)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)

## Support

For issues with:
- **n8n**: Visit [n8n Community](https://community.n8n.io/)
- **Render**: Check [Render Support](https://render.com/docs/support)
- **This setup**: Open an issue in this repository