# n8n Self-Hosted Setup

This repository provides configurations for running n8n both locally (for development) and on Google Cloud Run (for production).

## Overview

n8n is a workflow automation tool that allows you to connect various services and automate tasks. This setup includes:
- Local development environment with Docker Compose
- Production deployment on Google Cloud Run with Cloud SQL database
- Persistent storage for workflows and credentials
- Automated scripts for easy deployment

## Prerequisites

### Local Development
- Docker Desktop installed
- Docker Compose
- 4GB RAM available

### Production (Google Cloud Run)
- Google Cloud account with billing enabled
- `gcloud` CLI installed and authenticated
- Docker installed
- Existing Cloud SQL PostgreSQL database (optional)

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

## Production Deployment (Google Cloud Run)

### Cost Estimate
- **Monthly cost**: ~$30-55 (optimized setup)
- Includes: Cloud Run service, Cloud SQL database, Secret Manager
- Features: Auto-scaling, SSL certificates, monitoring

### 🚀 Quick Deployment

For a complete step-by-step migration guide, see: **[Cloud Run Migration Guide](docs/guides/CLOUD-RUN-MIGRATION.md)**

#### Configuration Setup
1. **Copy environment template**
   ```bash
   cp .env.example .env
   ```

2. **Edit configuration** (required values)
   ```bash
   # Edit .env with your specific values
   PROJECT_ID=your-gcp-project-id
   REGION=us-central1
   # ... other variables
   ```

#### One-Command Setup
```bash
# 1. Set up infrastructure
./scripts/cloud-run-setup.sh

# 2. Configure secrets (requires .env file)
./scripts/cloud-run-secrets.sh

# 3. Deploy n8n
./scripts/cloud-run-deploy.sh
```

### Production Features
- **Auto-scaling**: 1-10 instances based on traffic
- **High performance**: 2 CPU, 2GB RAM per instance
- **Secure**: All credentials in Google Secret Manager
- **SSL**: Automatic HTTPS with Google-managed certificates
- **Monitoring**: Integrated Cloud Run monitoring and logging
- **Cost-optimized**: Direct Cloud SQL connection (no VPC overhead)

### Custom Domain Setup
See: **[DNS Update Guide](docs/guides/DNS-UPDATE-GUIDE.md)**

```bash
gcloud beta run domain-mappings create \
  --service n8n-app \
  --domain your-domain.com \
  --region us-central1
```

## Project Structure

```
arrgh-n8n/
├── docker-compose.yml                 # Local development setup
├── Dockerfile.cloudrun                # Cloud Run optimized container
├── cloud-run-deployment.template.yaml # Knative service template with env variables
├── cloud-run-deployment.yaml          # Generated Cloud Run service config
├── .env.example                       # Environment variables template
├── config/
│   └── environments/                  # Environment-specific configurations
│       ├── production.env            # Production defaults
│       └── development.env           # Development defaults
├── scripts/                           # Deployment automation
│   ├── cloud-run-setup.sh            # Infrastructure setup
│   ├── cloud-run-secrets.sh          # Secret Manager configuration
│   ├── cloud-run-deploy.sh           # Build and deployment
│   ├── generate-configs.sh           # Template processing utility
│   └── monitor-domain.sh              # Domain migration monitoring
├── docs/
│   ├── guides/                        # Migration and setup guides
│   └── audit/                         # Migration verification
├── workflows/                         # n8n workflow backups
└── README.md                          # This file
```

## Configuration Architecture

This deployment uses **environment variable substitution** for secure, flexible configuration:

- **Template files** (`.template.yaml`) contain variables like `${PROJECT_ID}`, `${REGION}`
- **Environment files** (`.env`, `config/environments/*.env`) define actual values  
- **Generated files** are created by substituting variables into templates
- **Cloud Run** deploys using Knative service definitions (not raw Kubernetes YAML)

This approach ensures:
✅ **No hardcoded credentials** in source control  
✅ **Easy multi-environment deployments** (dev, staging, prod)  
✅ **Secure secret management** via Google Secret Manager  

See the [Configuration Guide](docs/guides/CONFIGURATION-GUIDE.md) for complete setup instructions.

## Database Configuration

This setup supports flexible database options:
- **Local**: PostgreSQL container (development)
- **Production**: Google Cloud SQL PostgreSQL
- **Connection**: Direct public IP connection (cost-optimized)
- **Security**: SSL/TLS encryption, Secret Manager for credentials

## Security Considerations

1. **Credentials**: All stored in Google Secret Manager
2. **Network**: Direct SSL/TLS connection to Cloud SQL
3. **Access**: Basic auth with strong passwords
4. **Updates**: Latest n8n version (1.98.1)
5. **Monitoring**: Cloud Run security scanning enabled

## Migration from Render/Other Platforms

This repository includes complete migration guides and automation:

- **[Migration Guide](docs/guides/CLOUD-RUN-MIGRATION.md)** - Complete step-by-step process
- **[Migration Success Report](docs/guides/migration-success.md)** - What to expect
- **[Migration Audit](docs/audit/MIGRATION-AUDIT.md)** - Verification of scripts and processes

### Migration Benefits
- **Cost savings**: ~$553/month saved from original setup
- **Better performance**: Dedicated resources, auto-scaling
- **Enhanced monitoring**: Cloud Run native tools
- **SSL included**: Google-managed certificates

## Troubleshooting

### Local Issues
- **Port 5678 in use**: Change port in docker-compose.yml
- **Database connection failed**: Ensure PostgreSQL container is running

### Cloud Run Issues
- **Service not starting**: Check logs with `gcloud run logs read --service=n8n-app`
- **Database connection failed**: Verify Cloud SQL credentials in Secret Manager
- **Build failures**: Check Docker platform (must be linux/amd64)

### Common Commands

```bash
# Local
docker-compose logs -f n8n           # View logs
docker-compose restart n8n           # Restart n8n

# Cloud Run
gcloud run services list             # List services
gcloud run logs read --service=n8n-app  # View logs
gcloud run services describe n8n-app    # Service details
```

## Cost Optimization

This setup is optimized for cost efficiency:

1. **No VPC Connector**: Direct Cloud SQL connection saves ~$518/month
2. **Right-sized resources**: 2 CPU, 2GB RAM for optimal performance
3. **Auto-scaling**: Pay only for what you use
4. **Shared infrastructure**: Reuse existing Cloud SQL databases

## Monitoring & Maintenance

### Performance Monitoring
```bash
# Check service health
gcloud run services describe n8n-app --region=us-central1

# Monitor resource usage
# Visit Google Cloud Console > Cloud Run > n8n-app > Metrics
```

### Updates
```bash
# Update to latest n8n version
./scripts/cloud-run-deploy.sh
```

## Next Steps

1. **Deploy**: Follow the [Migration Guide](docs/guides/CLOUD-RUN-MIGRATION.md)
2. **Custom Domain**: Configure your domain with [DNS Guide](docs/guides/DNS-UPDATE-GUIDE.md)
3. **Import Workflows**: Use the n8n API or web interface
4. **Set up Monitoring**: Configure Cloud Run alerts
5. **Cost Monitoring**: Set up billing alerts

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [Migration Guides](docs/guides/)

## Support

For issues with:
- **n8n**: Visit [n8n Community](https://community.n8n.io/)
- **Google Cloud**: Check [Cloud Support](https://cloud.google.com/support)
- **This setup**: Check the [guides](docs/guides/) or open an issue

---

**Current Status**: ✅ Production ready on Google Cloud Run  
**Last Updated**: July 2025  
**Migration**: Successfully completed from Render.com