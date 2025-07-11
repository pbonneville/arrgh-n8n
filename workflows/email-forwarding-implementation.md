# Email Forwarding Implementation for Arrgh Email Processor

## Overview
This document provides step-by-step instructions to add email forwarding functionality to the "Arrgh Email Processor" n8n workflow.

## Current Workflow
- **Name**: Arrgh Email Processor
- **ID**: cplr7F8xgOQ0lwpa
- **Backup Created**: 2025-07-11 (see `backups/2025-07-11/arrgh-email-processor-backup.json`)

## Requirements
- Forward all incoming emails to paul@paulbonneville.com
- Preserve original email formatting exactly as recipient would see it  
- Add "[n8n processed]" prefix to subject line
- Maintain parallel processing with existing entity extraction

## Implementation Steps

### Step 1: Open Workflow
1. Navigate to n8n.paulbonneville.com
2. Open the "Arrgh Email Processor" workflow
3. Ensure you're in edit mode

### Step 2: Add Email Forwarding Node

**Add New Node:**
1. Click the "+" button after "Extract Data from Email" node
2. Search for and select "Email Send" 
3. Name the node: "Forward Original Email"
4. Position it below the "Extract Data from Email" node

**Configure Node Parameters:**

| Field | Value |
|-------|-------|
| **From Email** | `arrgh@paulbonneville.com` |
| **To Email** | `paul@paulbonneville.com` |
| **Subject** | `[n8n processed] {{ $json.content.headers.Subject }}` |
| **HTML** | `{{ $json.content.body }}` |
| **SMTP Credentials** | AWS SES SMTP account (existing) |

### Step 3: Connect Nodes

**Add Connection:**
- From: "Extract Data from Email" (main output)
- To: "Forward Original Email" (main input)

**Verify Existing Connection Remains:**
- "Extract Data from Email" → "Call Newsletter API" should still exist

### Step 4: Updated Workflow Flow

```
Webhook (SNS) → Is Subscription Confirmation?
                ├── (True) → Confirm Subscription → Subscription Response
                └── (False) → Is Email Notification? 
                            └── (True) → Extract Data from Email
                                        ├── Call Newsletter API → Send Summary → Success Response
                                        └── Forward Original Email (NEW)
```

## Email Content Details

### Subject Format
- **Template**: `[n8n processed] {{ $json.content.headers.Subject }}`
- **Example**: "Newsletter Update" becomes "[n8n processed] Newsletter Update"

### Body Content
- **Source**: `{{ $json.content.body }}`
- **Description**: Cleaned HTML/text body after quoted-printable decoding
- **Preservation**: Maintains original formatting, links, and structure

### Key Features
- **Parallel Processing**: Forwarding runs simultaneously with entity extraction
- **Error Isolation**: If forwarding fails, entity extraction continues
- **Original Rendering**: Email appears exactly as intended recipient would see it
- **Consistent SMTP**: Uses same AWS SES credentials as summary emails

## Testing Procedure

### Test Email Forwarding
1. Send test email to: `test@arrgh.paulbonneville.com`
2. Verify two emails received at `paul@paulbonneville.com`:
   - **Forwarded Email**: Subject prefixed with "[n8n processed]"
   - **Summary Email**: "Arrgh! Email newsletter was parsed"
3. Check forwarded email formatting matches original
4. Confirm entity extraction still functions

### Validation Checklist
- [ ] Email forwarding node added and configured
- [ ] Connection from "Extract Data from Email" established  
- [ ] Subject prefix "[n8n processed]" appears correctly
- [ ] Email body renders with original formatting
- [ ] Entity extraction pipeline still works
- [ ] Summary notification email sent
- [ ] Webhook responds successfully

## Troubleshooting

### Common Issues

**1. SMTP Credentials**
- Ensure "AWS SES SMTP account" is selected
- Verify credentials are valid and active

**2. Template Variables**
- Subject: `[n8n processed] {{ $json.content.headers.Subject }}`
- Body: `{{ $json.content.body }}`
- Check for typos in variable names

**3. Node Connections**
- Verify connection from "Extract Data from Email" 
- Ensure existing workflow connections remain intact

**4. Email Not Forwarding**
- Check n8n execution logs for errors
- Verify paul@paulbonneville.com is correct recipient
- Test SMTP connection separately

## Rollback Procedure

If issues occur:
1. **Deactivate** the modified workflow
2. **Import backup** from `backups/2025-07-11/arrgh-email-processor-backup.json`
3. **Verify webhook URL** matches original configuration
4. **Reactivate** the restored workflow

## Monitoring

**Check Execution Logs:**
- Monitor n8n workflow executions
- Watch for email send failures
- Verify both forwarding and entity extraction complete

**Email Verification:**
- Confirm paul@paulbonneville.com receives forwarded emails
- Check email formatting and subject prefixes
- Validate entity extraction summaries still arrive

## File Locations

- **Backup**: `workflows/backups/2025-07-11/arrgh-email-processor-backup.json`
- **Documentation**: `workflows/email-forwarding-implementation.md`
- **Related**: Integration documented in arrgh-fastapi project CLAUDE.md