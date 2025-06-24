# AWS SES Inbound Email Processing - Deployment Guide

## Overview
This guide walks through deploying the complete AWS SES inbound email processing system that forwards emails to your n8n instance for automated processing.

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (version >= 1.0)
3. **Domain verified in AWS SES** for outbound email (should already be done)
4. **n8n instance running** on GKE with external access

## Deployment Steps

### 1. Deploy AWS Infrastructure

```bash
# Navigate to terraform directory
cd terraform/

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# - domain_name: Your domain (e.g., "paulbonneville.com")
# - n8n_webhook_url: Your n8n webhook URL
# - aws_region: AWS region (must match your SES region)

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply
```

### 2. Configure DNS MX Records

Follow the instructions in `docs/dns-mx-setup.md` to add the MX record to your domain's DNS.

The MX record should be:
```
10 inbound-smtp.us-east-1.amazonaws.com
```

### 3. Import n8n Workflow

1. **Access your n8n instance**:
   ```bash
   # Get the external IP
   kubectl get service n8n-service -n n8n
   ```

2. **Import the workflow**:
   - Log into n8n web interface
   - Go to "Workflows"
   - Click "Import from File"
   - Upload `workflows/inbound-email-processor.json`

3. **Configure AWS credentials** in n8n:
   - Go to "Credentials"
   - Add new "AWS" credential
   - Enter your AWS Access Key ID and Secret Access Key
   - Select the region where your S3 bucket is located

4. **Activate the workflow**:
   - Open the imported workflow
   - Click the toggle to activate it

### 4. Configure SNS Subscription

The Terraform deployment creates an SNS subscription to your n8n webhook, but you need to confirm it:

1. **Check your n8n logs** for subscription confirmation:
   ```bash
   kubectl logs -n n8n deployment/n8n --tail=50
   ```

2. **The workflow should automatically confirm** the SNS subscription when it receives the confirmation request.

## Architecture Flow

```
Email sent to your domain
    ↓
DNS MX record routes to AWS SES
    ↓
SES Receipt Rule processes email
    ↓
Email stored in S3 bucket
    ↓
SNS notification sent to n8n webhook
    ↓
n8n workflow downloads email from S3
    ↓
Email content parsed and processed
    ↓
Custom business logic executed
```

## Testing the Setup

### 1. Send Test Email
```bash
# Send a test email to your domain
echo "Test email body for n8n processing" | mail -s "Test Subject" test@yourdomain.com
```

### 2. Monitor Processing
```bash
# Check n8n logs
kubectl logs -n n8n deployment/n8n --tail=20 -f

# Check AWS CloudWatch logs (if enabled)
aws logs tail /aws/lambda/ses-processing --follow

# Check S3 for stored emails
aws s3 ls s3://n8n-inbound-emails-production/emails/
```

### 3. Verify in n8n Interface
- Go to n8n "Executions" tab
- You should see workflow executions triggered by incoming emails
- Check execution details to see parsed email data

## Customizing Email Processing

The n8n workflow includes a "Process Email Logic" node where you can add custom logic:

```javascript
// Example: Process different email types
const bodyText = $json.body.toLowerCase();

if (bodyText.includes('invoice')) {
  // Extract invoice data and create records
  return { type: 'invoice', processed: true };
} else if (bodyText.includes('support')) {
  // Create support ticket
  return { type: 'support_ticket', processed: true };
} else {
  // Default processing
  return { type: 'general', processed: true };
}
```

## Security Considerations

1. **IAM Permissions**: The SES role has minimal permissions (S3 PutObject, SNS Publish)
2. **S3 Bucket**: Private bucket with lifecycle policy (emails deleted after 30 days)
3. **Webhook Security**: Consider adding authentication to your n8n webhook
4. **Email Content**: Be careful with email attachments and suspicious content

## Monitoring and Maintenance

### CloudWatch Metrics
Monitor these metrics in AWS CloudWatch:
- SES receipt rule executions
- S3 object creation events
- SNS message delivery success/failure

### S3 Lifecycle
Emails are automatically deleted after 30 days. Adjust in `terraform/main.tf` if needed:

```hcl
expiration {
  days = 90  # Keep emails for 90 days instead
}
```

### Cost Monitoring
- SES: $0.10 per 1,000 emails received
- S3: Storage costs for email files
- SNS: $0.50 per 1 million notifications

## Troubleshooting

### Common Issues

1. **Emails not being received**:
   - Check MX record with `dig MX yourdomain.com`
   - Verify SES receipt rule is active
   - Check S3 bucket permissions

2. **n8n workflow not triggering**:
   - Confirm SNS subscription is confirmed
   - Check n8n webhook URL accessibility
   - Verify AWS credentials in n8n

3. **Email parsing errors**:
   - Check S3 bucket for email files
   - Verify AWS credentials can access S3
   - Review n8n execution logs

### Useful Commands

```bash
# Check SES receipt rules
aws ses describe-receipt-rule-set --rule-set-name n8n-inbound-production

# List emails in S3
aws s3 ls s3://n8n-inbound-emails-production/emails/ --recursive

# Check SNS topic subscriptions
aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn)

# Test MX record
dig MX yourdomain.com +short
```

## Cleanup

To remove all AWS resources:

```bash
cd terraform/
terraform destroy
```

Note: This will delete all stored emails and disable inbound email processing.