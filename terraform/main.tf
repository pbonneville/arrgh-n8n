terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for email receiving"
  type        = string
  default     = "paulbonneville.com"
}

variable "n8n_webhook_url" {
  description = "n8n webhook URL for email notifications"
  type        = string
  default     = "https://n8n.paulbonneville.com/webhook/inbound-email"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# S3 bucket for storing incoming emails
resource "aws_s3_bucket" "email_storage" {
  bucket = "n8n-inbound-emails-${var.environment}"
}

resource "aws_s3_bucket_versioning" "email_storage" {
  bucket = aws_s3_bucket.email_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "email_storage" {
  bucket = aws_s3_bucket.email_storage.id

  rule {
    id     = "delete_old_emails"
    status = "Enabled"

    filter {
      prefix = "emails/"
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "email_storage" {
  bucket = aws_s3_bucket.email_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SNS topic for email notifications
resource "aws_sns_topic" "email_notifications" {
  name = "n8n-email-notifications-${var.environment}"
}

# SNS topic subscription to n8n webhook (manual creation after workflow confirmation)
# resource "aws_sns_topic_subscription" "n8n_webhook" {
#   topic_arn = aws_sns_topic.email_notifications.arn
#   protocol  = "https"
#   endpoint  = var.n8n_webhook_url
# }

# IAM role for SES to access S3 and SNS
resource "aws_iam_role" "ses_role" {
  name = "ses-email-processing-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for SES to write to S3
resource "aws_iam_role_policy" "ses_s3_policy" {
  name = "ses-s3-policy-${var.environment}"
  role = aws_iam_role.ses_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.email_storage.arn}/*"
      }
    ]
  })
}

# IAM policy for SES to publish to SNS
resource "aws_iam_role_policy" "ses_sns_policy" {
  name = "ses-sns-policy-${var.environment}"
  role = aws_iam_role.ses_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.email_notifications.arn
      }
    ]
  })
}

# SES receipt rule set
resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = "n8n-inbound-${var.environment}"
}

# Make this rule set active
resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = aws_ses_receipt_rule_set.main.rule_set_name
}

# SES receipt rule for processing emails
resource "aws_ses_receipt_rule" "email_processing" {
  name          = "process-inbound-emails"
  rule_set_name = aws_ses_receipt_rule_set.main.rule_set_name
  recipients    = [var.domain_name]
  enabled       = true
  scan_enabled  = true

  # Store email in S3
  s3_action {
    bucket_name       = aws_s3_bucket.email_storage.bucket
    object_key_prefix = "emails/"
    position          = 1
  }

  # Notify n8n via SNS
  sns_action {
    topic_arn = aws_sns_topic.email_notifications.arn
    position  = 2
  }

  depends_on = [aws_s3_bucket_policy.ses_policy]
}

# S3 bucket policy to allow SES to write
resource "aws_s3_bucket_policy" "ses_policy" {
  bucket = aws_s3_bucket.email_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSESPuts"
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.email_storage.arn}/*"
        Condition = {
          StringEquals = {
            "aws:Referer" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for storing emails"
  value       = aws_s3_bucket.email_storage.bucket
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for email notifications"
  value       = aws_sns_topic.email_notifications.arn
}

output "ses_rule_set_name" {
  description = "Name of the SES receipt rule set"
  value       = aws_ses_receipt_rule_set.main.rule_set_name
}

output "mx_record" {
  description = "MX record to add to DNS"
  value       = "10 inbound-smtp.${var.aws_region}.amazonaws.com"
}