# AWS Infrastructure Overview

This document describes the AWS infrastructure required for the inbound email processing system.

## Infrastructure Components

The email processing system uses the following AWS services:

### 1. Amazon SES (Simple Email Service)
- **Purpose**: Receives inbound emails for the configured domain
- **Configuration**: 
  - Verified domain with MX records pointing to AWS SES
  - Receipt rule set for processing incoming emails
  - Actions: Store in S3 and notify via SNS

### 2. Amazon S3 Bucket
- **Purpose**: Stores received emails temporarily
- **Configuration**:
  - Lifecycle policy: Auto-delete emails after 30 days
  - Encryption: Server-side encryption enabled
  - Access: Restricted to SES service only

### 3. Amazon SNS Topic
- **Purpose**: Sends notifications to n8n webhook when emails arrive
- **Configuration**:
  - HTTPS subscription to n8n webhook endpoint
  - Delivery retry policy configured

### 4. IAM Roles and Policies
- **SES Role**: Allows SES to write to S3 and publish to SNS
- **S3 Bucket Policy**: Restricts access to SES service only

## Required Configuration

To set up this infrastructure, you need:

1. **Domain Configuration**:
   - Add MX record pointing to SES endpoint (see dns-mx-setup.md)
   - Verify domain ownership in SES

2. **Environment Variables** (see .env.example):
   - `EMAIL_DOMAIN`: Your verified domain
   - `EMAIL_SUBDOMAIN`: Subdomain for receiving emails
   - `N8N_WEBHOOK_URL`: Your n8n webhook endpoint

## Infrastructure as Code

The infrastructure was originally deployed using Terraform but has been removed from this public repository for security reasons. If you need to recreate the infrastructure:

1. Use the AWS Console to manually create the resources, or
2. Create your own Terraform configuration based on this documentation
3. Reference the AWS documentation for SES email receiving setup

## Security Considerations

- Never commit Terraform state files to version control
- Keep infrastructure code in a private repository
- Use environment variables for all sensitive configuration
- Regularly rotate IAM credentials
- Monitor CloudWatch logs for unusual activity

## Maintenance

- Check S3 bucket size periodically
- Monitor SNS delivery failures in CloudWatch
- Review SES spam/virus scan results
- Update n8n webhook URL if it changes