# n8n Workflow Backup - July 11, 2025

## Backup Details

**Date**: July 11, 2025  
**Purpose**: Backup before implementing email forwarding functionality  
**Workflow**: Arrgh Email Processor (ID: cplr7F8xgOQ0lwpa)

## Files

### arrgh-email-processor-backup.json
Complete workflow export including:
- All node configurations and parameters
- Workflow connections and flow logic
- Webhook configuration and test data
- SMTP credentials references
- Python code for email parsing

## Original Workflow Structure

```
Webhook (AWS SNS) 
├── Is Subscription Confirmation?
│   ├── (True) → Confirm Subscription → Subscription Response
│   └── (False) → Is Email Notification?
│               └── (True) → Extract Data from Email 
│                           └── Call Newsletter API 
│                               └── Send Summary Email 
│                                   └── Success Response
```

## Key Components

**Nodes:**
1. **Webhook**: Receives AWS SNS notifications from SES
2. **Subscription Handling**: Manages AWS SNS subscription confirmations
3. **Email Parsing**: Python code extracts and parses email content
4. **API Integration**: Calls arrgh-fastapi for entity extraction
5. **Summary Notification**: Sends processing results to paul@paulbonneville.com

**Technical Details:**
- **Webhook Path**: `/webhook/inbound-email`
- **API Endpoint**: `https://arrgh-fastapi-860937201650.us-central1.run.app/newsletter/process`
- **SMTP**: AWS SES credentials (ID: sC34ufIj3qJLoA95)
- **S3 Storage**: `n8n-inbound-emails-production` bucket

## Restoration Instructions

**To restore this workflow:**

1. **Import JSON File**:
   - Go to n8n.paulbonneville.com
   - Import `arrgh-email-processor-backup.json`
   - Verify all node configurations

2. **Verify Connections**:
   - Check webhook URL configuration
   - Confirm SMTP credentials are linked
   - Test API endpoint connectivity

3. **Activate Workflow**:
   - Ensure workflow is set to active
   - Verify webhook is receiving SNS notifications
   - Test with sample email

## Modification History

**Pre-Backup State**:
- Single email processing path
- Entity extraction and summary notification only
- No email forwarding functionality

**Planned Changes** (see `../email-forwarding-implementation.md`):
- Add email forwarding to paul@paulbonneville.com
- Preserve original email formatting
- Parallel processing with entity extraction
- Subject prefix "[n8n processed]"

## Related Files

- **Implementation Guide**: `../email-forwarding-implementation.md`
- **arrgh-fastapi Integration**: See CLAUDE.md in arrgh-fastapi project
- **Previous Backups**: 
  - `../Arrgh_Email_Processor_20250630_232044.json`
  - `../Arrgh_Email_Processor_20250707_084500.json`