# Configuration Guide for n8n Cloud Run Deployment

This guide explains how to configure environment variables and templates for secure, flexible deployment across different environments.

## Overview

The Cloud Run deployment system uses environment variable substitution to avoid hardcoding sensitive information in configuration files. This approach provides:

- **Security**: No credentials in git repository
- **Flexibility**: Easy deployment to different projects/environments
- **Maintainability**: Clear separation of configuration from code

## Configuration Files

### Environment Templates

- **`.env.example`** - Template showing all required variables (checked into git)
- **`config/environments/production.env`** - Production-specific defaults
- **`config/environments/development.env`** - Development-specific defaults
- **`.env`** - Your actual configuration (not checked into git)

### Deployment Templates

- **`cloud-run-deployment.template.yaml`** - Template with variables (checked into git)
- **`cloud-run-deployment.yaml`** - Generated final configuration (not for editing)

## Required Environment Variables

### Google Cloud Configuration
```bash
# Core GCP settings
PROJECT_ID=your-gcp-project-id        # Required: Your GCP project ID
REGION=us-central1                    # Required: GCP region for resources
REPO_NAME=n8n-repo                    # Required: Artifact Registry repository name
SERVICE_NAME=n8n-app                  # Required: Cloud Run service name
```

### n8n Configuration
```bash
# Authentication
N8N_BASIC_AUTH_PASSWORD=secure-password  # Required: Admin password
N8N_API_KEY=your-api-key                # Required: n8n API key
N8N_ENCRYPTION_KEY=encryption-key       # Required: Data encryption key

# Basic settings
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
```

### Database Configuration
```bash
# Cloud SQL connection details
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=your-cloud-sql-ip    # Required: Cloud SQL instance IP
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n              # Required: Database name
DB_POSTGRESDB_USER=postgres              # Required: Database user
DB_POSTGRESDB_PASSWORD=db-password       # Required: Database password
DB_POSTGRESDB_SSL_ENABLED=false
```

### Email Configuration (AWS SES)
```bash
# SMTP settings
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=email-smtp.us-east-1.amazonaws.com  # Required for email
N8N_SMTP_PORT=587
N8N_SMTP_SSL=false
N8N_SMTP_STARTTLS=true
N8N_SMTP_USER=your-aws-ses-username               # Required for email
N8N_SMTP_PASS=your-aws-ses-password               # Required for email
N8N_DEFAULT_EMAIL=noreply@yourdomain.com          # Required for email
N8N_SMTP_SENDER=n8n@yourdomain.com                # Required for email
```

### API Keys for Integrations
```bash
# External service API keys
ANTHROPIC_API_KEY=your-anthropic-key              # Optional: For Claude integration
AWS_ACCESS_KEY_ID=your-aws-key                    # Optional: For AWS services
AWS_SECRET_ACCESS_KEY=your-aws-secret             # Optional: For AWS services
```

## Setup Process

### 1. Initial Configuration

1. **Copy the template**:
   ```bash
   cp .env.example .env
   ```

2. **Edit your configuration**:
   ```bash
   # Edit .env with your actual values
   nano .env
   ```

3. **Validate configuration**:
   ```bash
   ./scripts/generate-configs.sh
   ```

### 2. Environment-Specific Setup

For different environments, you can use pre-configured templates:

```bash
# Use production settings
./scripts/generate-configs.sh config/environments/production.env

# Use development settings  
./scripts/generate-configs.sh config/environments/development.env

# Use custom environment file
./scripts/generate-configs.sh path/to/custom.env
```

### 3. Configuration Validation

The `generate-configs.sh` script validates your configuration:

- Checks for required variables
- Validates YAML syntax (if kubectl available)
- Generates deployment summary
- Creates ready-to-deploy configuration

## Security Best Practices

### 1. Environment Files
- **Never commit `.env` files** to git (already in .gitignore)
- **Use strong passwords** for all authentication
- **Rotate API keys** regularly
- **Use unique encryption keys** per environment

### 2. Template Variables
- **Template files** (`.template.yaml`) are safe to commit
- **Generated files** should not be edited manually
- **Validate templates** before deployment

### 3. Secret Management
- All sensitive data goes to **Google Secret Manager**
- Environment variables are used only for **non-sensitive configuration**
- Database credentials and API keys are stored as **secrets**

## Common Configuration Patterns

### Multi-Environment Setup

Create environment-specific configuration files:

```bash
# Production
cat > config/environments/prod.env << EOF
PROJECT_ID=my-prod-project
REGION=us-central1
SERVICE_NAME=n8n-prod
EOF

# Staging
cat > config/environments/staging.env << EOF
PROJECT_ID=my-staging-project
REGION=us-west1
SERVICE_NAME=n8n-staging
EOF
```

### CI/CD Integration

In your CI/CD pipeline:

```bash
# Load environment for current branch/environment
case "$BRANCH" in
  "main")
    ENV_FILE="config/environments/production.env"
    ;;
  "staging")
    ENV_FILE="config/environments/staging.env"
    ;;
  *)
    ENV_FILE="config/environments/development.env"
    ;;
esac

# Generate configuration
./scripts/generate-configs.sh "$ENV_FILE"

# Deploy
./scripts/cloud-run-deploy.sh
```

## Troubleshooting

### Missing Variables
If you see "Missing required environment variables":
1. Check your `.env` file exists
2. Verify all required variables are set
3. Ensure no typos in variable names
4. Check for proper `KEY=value` format (no spaces around =)

### Template Processing Errors
If `envsubst` fails:
1. Install gettext: `brew install gettext` (macOS) or `apt-get install gettext-base` (Ubuntu)
2. Check template syntax: variables should be `${VARIABLE_NAME}`
3. Ensure all referenced variables are defined

### Deployment Configuration Issues
If deployment fails:
1. Review generated `cloud-run-deployment-generated.yaml`
2. Check `deployment-summary.txt` for configuration details
3. Validate GCP project and permissions
4. Ensure all required secrets exist in Secret Manager

## Advanced Usage

### Custom Templates

You can create your own templates:

1. Copy existing template:
   ```bash
   cp cloud-run-deployment.template.yaml my-custom.template.yaml
   ```

2. Modify as needed, using `${VARIABLE_NAME}` syntax

3. Generate configuration:
   ```bash
   envsubst < my-custom.template.yaml > my-custom-generated.yaml
   ```

### Variable Validation

Add custom validation to your deployment scripts:

```bash
# Check critical variables
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
    echo "Error: PROJECT_ID and REGION must be set"
    exit 1
fi

# Validate project exists
if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
    echo "Error: Project $PROJECT_ID not found or not accessible"
    exit 1
fi
```

## Related Documentation

- [Cloud Run Migration Guide](CLOUD-RUN-MIGRATION.md) - Complete deployment process
- [DNS Update Guide](DNS-UPDATE-GUIDE.md) - Custom domain configuration
- [Migration Audit](../audit/MIGRATION-AUDIT.md) - Verification procedures

---

**Security Note**: Always review generated configuration files before deployment to ensure no sensitive data is accidentally exposed.