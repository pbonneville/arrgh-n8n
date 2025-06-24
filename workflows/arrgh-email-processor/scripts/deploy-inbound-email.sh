#!/bin/bash

# AWS SES Inbound Email Processing Deployment Script
# This script deploys the complete SES inbound email processing infrastructure

set -e

echo "=== AWS SES Inbound Email Processing Deployment ==="
echo

# Check prerequisites
echo "Checking prerequisites..."

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi

# Check if Terraform/OpenTofu is installed
if command -v tofu &> /dev/null; then
    TERRAFORM_CMD="tofu"
elif command -v terraform &> /dev/null; then
    TERRAFORM_CMD="terraform"
else
    echo "❌ Terraform/OpenTofu is not installed. Please install it first."
    exit 1
fi

# Check if kubectl is installed and configured
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    exit 1
fi

# Check if connected to GKE cluster
if ! kubectl get nodes &> /dev/null; then
    echo "❌ Not connected to Kubernetes cluster. Run:"
    echo "   gcloud container clusters get-credentials n8n-cluster --region=us-central1"
    exit 1
fi

echo "✅ All prerequisites met"
echo

# Get current AWS account and region
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")

echo "AWS Account: $AWS_ACCOUNT"
echo "AWS Region: $AWS_REGION"
echo

# Prompt for domain name
read -p "Enter your domain name (e.g., paulbonneville.com): " DOMAIN_NAME
if [[ -z "$DOMAIN_NAME" ]]; then
    echo "❌ Domain name is required"
    exit 1
fi

# Use the HTTPS domain for n8n
N8N_WEBHOOK_URL="https://n8n.paulbonneville.com/webhook/inbound-email"
echo "n8n webhook URL: $N8N_WEBHOOK_URL"
echo

# Create terraform.tfvars
echo "Creating Terraform configuration..."
cd terraform/

cat > terraform.tfvars << EOF
aws_region = "$AWS_REGION"
domain_name = "$DOMAIN_NAME"
n8n_webhook_url = "$N8N_WEBHOOK_URL"
environment = "production"
EOF

echo "✅ Created terraform.tfvars"

# Initialize and deploy with Terraform/OpenTofu
echo
echo "Deploying AWS infrastructure with $TERRAFORM_CMD..."
$TERRAFORM_CMD init

echo
echo "Planning deployment..."
$TERRAFORM_CMD plan

echo
read -p "Do you want to apply these changes? (y/N): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo
echo "Applying configuration..."
$TERRAFORM_CMD apply -auto-approve

# Get outputs
S3_BUCKET=$($TERRAFORM_CMD output -raw s3_bucket_name)
SNS_TOPIC_ARN=$($TERRAFORM_CMD output -raw sns_topic_arn)
MX_RECORD=$($TERRAFORM_CMD output -raw mx_record)

echo
echo "✅ AWS infrastructure deployed successfully!"
echo
echo "=== Next Steps ==="
echo
echo "1. Add MX record to your DNS:"
echo "   Type: MX"
echo "   Name: @ (or $DOMAIN_NAME)"
echo "   Value: $MX_RECORD"
echo "   Priority: 10"
echo
echo "2. Import n8n workflow:"
echo "   - Go to n8n web interface at https://n8n.paulbonneville.com"
echo "   - Import workflows/inbound-email-processor.json"
echo "   - Add AWS credentials in n8n"
echo "   - Activate the workflow"
echo
echo "3. Test the setup:"
echo "   - Send email to test@$DOMAIN_NAME"
echo "   - Check n8n execution logs"
echo
echo "4. Monitor S3 bucket for emails:"
echo "   aws s3 ls s3://$S3_BUCKET/emails/"
echo
echo "=== Outputs ==="
echo "S3 Bucket: $S3_BUCKET"
echo "SNS Topic: $SNS_TOPIC_ARN"
echo "MX Record: $MX_RECORD"
echo "Webhook URL: $N8N_WEBHOOK_URL"
echo
echo "✅ Deployment complete! See docs/inbound-email-deployment.md for details."