# n8n Workflow Backup Summary

**Backup Date**: June 26, 2025 - 16:26:33  
**Source**: n8n GKE Instance (https://n8n.paulbonneville.com)  
**Total Workflows**: 4

## Backed Up Workflows

### 1. Anthropic Chat
- **File**: `Anthropic_Chat.json`
- **ID**: `LvIGJQ5WUwOXzwpO`
- **Status**: Active
- **Created**: 2025-06-19T03:56:38.520Z
- **Last Updated**: 2025-06-19T21:53:43.734Z
- **Description**: AI chat interface using Claude 4 Sonnet with memory

### 2. Arrgh Email Processor
- **File**: `Arrgh_Email_Processor.json`
- **ID**: `B59fialntF5x0ZUC`
- **Status**: Active
- **Created**: 2025-06-23T07:47:12.154Z
- **Last Updated**: 2025-06-23T21:56:44.748Z
- **Description**: AWS SES inbound email processing with S3 storage and SNS notifications

### 3. Google Gemini Chat
- **File**: `Google_Gemini_Chat.json`
- **ID**: `EQdTiITfb7SOjxAi`
- **Status**: Active
- **Created**: 2025-06-23T05:17:17.391Z
- **Last Updated**: 2025-06-23T05:28:57.530Z
- **Description**: AI chat interface using Google Gemini 2.5 Pro with memory

### 4. OpenAI Chat
- **File**: `OpenAI_Chat.json`
- **ID**: `hQyzDge8Cz666t6r`
- **Status**: Active
- **Created**: 2025-06-18T23:30:24.916Z
- **Last Updated**: 2025-06-23T05:12:24.778Z
- **Description**: AI chat interface using GPT-4.1 with memory

## Notes

- All workflows are currently active
- Credentials are referenced by ID but not included in backup for security
- Static data and pinned data are preserved
- Webhook IDs and node positions are maintained
- Version IDs are preserved for exact restoration

## Restoration Instructions

1. Import each JSON file into new n8n instance
2. Reconfigure credentials for each workflow:
   - Anthropic API credentials
   - AWS credentials for email processor
   - Google Gemini API credentials
   - OpenAI API credentials
3. Verify webhook URLs and update if necessary
4. Test each workflow after import

## Security Note

This backup contains workflow structure and logic but does NOT include:
- API keys or credentials
- Sensitive environment variables
- User data or execution history