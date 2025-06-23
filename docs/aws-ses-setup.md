# AWS SES Email Configuration for n8n

This guide explains how to set up AWS SES (Simple Email Service) as the email provider for your n8n instance.

## Prerequisites

- AWS account with SES access
- Verified domain or email address in SES
- n8n instance deployed on GKE

## AWS SES Setup

### 1. Verify Domain or Email Address

1. Go to AWS SES Console
2. Navigate to "Verified identities"
3. Click "Create identity"
4. Choose either:
   - **Domain**: Verify entire domain (recommended)
   - **Email address**: Verify single email address

### 2. Move Out of Sandbox (Production)

By default, SES is in sandbox mode with restrictions:
- Can only send to verified emails
- Limited sending rate

To request production access:
1. Go to "Account dashboard" in SES
2. Click "Request production access"
3. Fill out the form with your use case

### 3. Create SMTP Credentials

1. In SES Console, go to "SMTP settings"
2. Note your SMTP endpoint (e.g., `email-smtp.us-west-2.amazonaws.com`)
3. Click "Create SMTP credentials"
4. Save the generated:
   - SMTP Username
   - SMTP Password

## n8n Configuration

### 1. Update Kubernetes Secrets

Edit `kubernetes/secrets.yaml`:

```yaml
# AWS SES SMTP credentials
N8N_SMTP_USER: "YOUR_ACTUAL_SES_SMTP_USERNAME"
N8N_SMTP_PASS: "YOUR_ACTUAL_SES_SMTP_PASSWORD"
```

### 2. Update ConfigMap (if needed)

The `kubernetes/configmap.yaml` is pre-configured with:

```yaml
# Email configuration (AWS SES)
N8N_EMAIL_MODE: "smtp"
N8N_SMTP_HOST: "email-smtp.us-west-2.amazonaws.com"  # Change to your region
N8N_SMTP_PORT: "587"
N8N_SMTP_SSL: "true"
N8N_DEFAULT_EMAIL: "noreply@paulbonneville.com"  # Change to your verified email
```

Update:
- `N8N_SMTP_HOST`: Use your SES region's endpoint
- `N8N_DEFAULT_EMAIL`: Use your verified email address

### 3. Deploy Changes

```bash
# Apply the updated configurations
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml

# Restart n8n to pick up changes
kubectl rollout restart deployment/n8n -n n8n

# Check deployment status
kubectl rollout status deployment/n8n -n n8n
```

## Testing Email Functionality

1. **Password Reset**:
   - Go to n8n login page
   - Click "Forgot password?"
   - Enter your email
   - Check if reset email is received

2. **Test Workflow**:
   - Create a simple workflow with "Send Email" node
   - Configure with test recipient
   - Execute and verify delivery

## Troubleshooting

### Check Logs
```bash
kubectl logs -n n8n deployment/n8n --tail=100
```

### Common Issues

1. **Authentication Failed**:
   - Verify SMTP credentials are correct
   - Ensure credentials are base64 encoded if required

2. **Connection Timeout**:
   - Check SMTP host and port
   - Verify security group allows outbound SMTP

3. **Email Not Sending**:
   - Confirm sender email is verified in SES
   - Check if still in SES sandbox mode

## SES Regions and Endpoints

| Region | SMTP Endpoint |
|--------|--------------|
| US East (N. Virginia) | email-smtp.us-east-1.amazonaws.com |
| US West (Oregon) | email-smtp.us-west-2.amazonaws.com |
| EU (Ireland) | email-smtp.eu-west-1.amazonaws.com |
| EU (Frankfurt) | email-smtp.eu-central-1.amazonaws.com |
| Asia Pacific (Sydney) | email-smtp.ap-southeast-2.amazonaws.com |

## Security Best Practices

1. Use IAM user with minimal SES permissions
2. Rotate SMTP credentials regularly
3. Monitor SES sending metrics
4. Set up bounce/complaint handling
5. Configure SPF, DKIM, and DMARC for domain

## Additional Resources

- [AWS SES Documentation](https://docs.aws.amazon.com/ses/)
- [n8n Email Configuration](https://docs.n8n.io/hosting/configuration/environment-variables/#email)
- [SES SMTP Integration Guide](https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp.html)