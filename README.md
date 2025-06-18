# n8n Self-Hosted Setup

This repository provides configurations for running n8n both locally (for development) and on Google Kubernetes Engine (for production).

## Overview

n8n is a workflow automation tool that allows you to connect various services and automate tasks. This setup includes:
- Local development environment with Docker Compose
- Production deployment on GKE with Supabase database
- Persistent storage for workflows and credentials

## Prerequisites

### Local Development
- Docker Desktop installed
- Docker Compose
- 4GB RAM available

### Production (GKE)
- Google Cloud account with billing enabled
- gcloud CLI installed and configured
- kubectl installed
- Supabase account and database

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

## Production Deployment (GKE)

### Cost Estimate
- **Monthly cost**: $0-40 (with GKE free tier)
- **Without free tier**: ~$110/month
- Includes: GKE cluster management, compute resources, and load balancer

### Setup Steps

1. **Create GKE Autopilot Cluster**
   ```bash
   gcloud container clusters create-auto n8n-cluster \
     --region=us-central1 \
     --release-channel=regular
   ```

2. **Configure kubectl**
   ```bash
   gcloud container clusters get-credentials n8n-cluster --region=us-central1
   ```

3. **Update Secrets**
   Edit `kubernetes/secrets.yaml`:
   - Set secure passwords for `N8N_BASIC_AUTH_PASSWORD` and `N8N_ENCRYPTION_KEY`
   - Update `DB_POSTGRESDB_PASSWORD` with your Supabase password

4. **Update Database Configuration**
   Edit `kubernetes/configmap.yaml`:
   - Update `DB_POSTGRESDB_HOST` with your Supabase host

5. **Deploy n8n**
   ```bash
   kubectl apply -f kubernetes/
   ```

6. **Get External IP**
   ```bash
   kubectl get service n8n-service -n n8n
   ```
   Wait for EXTERNAL-IP to be assigned (may take 2-3 minutes)

7. **Access n8n**
   - URL: `http://<EXTERNAL-IP>`
   - Username: `admin`
   - Password: (what you set in secrets.yaml)

### Production Features
- Persistent storage via Supabase
- Auto-scaling capabilities
- Session affinity for webhooks
- Health checks and auto-recovery
- SSL can be added with Ingress

### Monitoring

Check pod status:
```bash
kubectl get pods -n n8n
```

View logs:
```bash
kubectl logs -n n8n -l app=n8n
```

### Updating n8n

1. Update the deployment:
   ```bash
   kubectl set image deployment/n8n n8n=n8nio/n8n:new-version -n n8n
   ```

2. Or edit and reapply:
   ```bash
   kubectl apply -f kubernetes/deployment.yaml
   ```

## Project Structure

```
arrgh-n8n/
├── docker-compose.yml     # Local development setup
├── .env.example          # Environment variables template
├── kubernetes/           # GKE deployment files
│   ├── namespace.yaml    # Kubernetes namespace
│   ├── configmap.yaml    # n8n configuration
│   ├── secrets.yaml      # Sensitive credentials
│   ├── deployment.yaml   # n8n deployment (1 CPU, 2GB RAM)
│   └── service.yaml      # LoadBalancer service
├── README.md            # This file
├── PLANNING.md          # Original architecture planning
└── .gitignore          # Git ignore rules
```

## Database Configuration

This setup uses Supabase for the production database:
- **Why Supabase**: Managed PostgreSQL, easy setup, generous free tier
- **Free tier**: 500MB storage, suitable for personal use
- **Connection**: Direct connection on port 5432

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

### GKE Issues
- **Pod not starting**: Check logs with `kubectl logs`
- **No external IP**: Ensure GKE has permission to create load balancers
- **Database connection failed**: Verify Supabase credentials and firewall rules

### Common Commands

```bash
# Local
docker-compose logs -f n8n    # View logs
docker-compose restart n8n    # Restart n8n

# GKE
kubectl describe pod -n n8n   # Detailed pod info
kubectl scale deployment/n8n --replicas=0 -n n8n  # Stop n8n
kubectl scale deployment/n8n --replicas=1 -n n8n  # Start n8n
```

## Cost Optimization

1. **Use GKE Autopilot** - Pay only for pods, not nodes
2. **Single replica** - Sufficient for personal use
3. **Leverage free tier** - $74.40 monthly credit
4. **Consider alternatives** if costs are high:
   - Railway.app (~$5-10/month)
   - Keep using local Docker

## Next Steps

1. **Add custom domain** with Google Cloud DNS
2. **Enable HTTPS** with cert-manager and Let's Encrypt
3. **Set up backups** for Supabase database
4. **Configure monitoring** with Google Cloud Monitoring
5. **Add authentication** with Identity-Aware Proxy

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Supabase Documentation](https://supabase.com/docs)

## Support

For issues with:
- **n8n**: Visit [n8n Community](https://community.n8n.io/)
- **GKE**: Check [Google Cloud Support](https://cloud.google.com/support)
- **This setup**: Open an issue in this repository