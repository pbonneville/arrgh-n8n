# Arrgh Email Processor - n8n Workflow Documentation

## Overview
This n8n workflow processes inbound emails received through AWS SES (Simple Email Service). Emails sent to `@arrgh.paulbonneville.com` are automatically processed, parsed, and can trigger custom business logic.

## Architecture Flow

```
📧 Email sent to @arrgh.paulbonneville.com
    ↓
🌐 DNS MX record routes to AWS SES
    ↓
📦 SES stores email in S3 bucket (n8n-inbound-emails-production)
    ↓
🔔 SNS notification sent to n8n webhook
    ↓
⚙️ n8n workflow processes the notification
    ↓
📊 Custom business logic executes
    ↓
✅ Response sent back to AWS
```

## Workflow Components

### 1. **Webhook** (Entry Point)
- **Purpose**: Receives HTTP POST requests from AWS SNS
- **Endpoint**: `https://n8n.paulbonneville.com/webhook/inbound-email`
- **Method**: POST
- **Input**: SNS notification payload with email metadata

### 2. **Is Subscription Confirmation?** (Router)
- **Purpose**: Determines if incoming request is SNS subscription confirmation or email notification
- **Condition**: Checks `x-amz-sns-message-type` header
- **Logic**: 
  - `SubscriptionConfirmation` → Goes to subscription confirmation flow
  - Other → Goes to email processing flow

### 3. **Confirm Subscription** (AWS Integration)
- **Purpose**: Automatically confirms SNS subscription to enable email notifications
- **Method**: GET request to AWS SubscribeURL
- **URL**: Extracted from `$json.body.parseJson().SubscribeURL`
- **Trigger**: Only when subscription confirmation is needed

**Why This Is Necessary:**

AWS SES and SNS are two separate services that work together for real-time email processing:

1. **SES (Simple Email Service)**: Receives emails and stores them in S3
2. **SNS (Simple Notification Service)**: Sends real-time notifications about email events

Without SNS confirmation, the flow would be:
```
📧 Email arrives → 📦 SES stores in S3 → ❌ NO notification to n8n
```

You'd have to constantly poll S3 to check for new emails, which is inefficient and has delays.

With SNS confirmation, the flow becomes:
```
📧 Email arrives → 📦 SES stores in S3 → 🔔 SNS immediately notifies n8n → ⚡ Real-time processing
```

**The Confirmation Process:**
1. When you create an SNS subscription via Terraform, AWS requires verification that you own the endpoint
2. SNS sends a `SubscriptionConfirmation` message to your webhook with a special `SubscribeURL`
3. You must make a GET request to that URL to prove you control the endpoint
4. Only after confirmation will SNS send actual email notifications

**Security Reason:** This prevents malicious actors from subscribing random URLs to SNS topics and spamming them with notifications.

**Alternative Approaches (Why We Don't Use Them):**

1. **S3 Polling**: Check S3 bucket every few minutes for new emails
   - ❌ Delayed processing (minutes instead of seconds)
   - ❌ Higher AWS costs (constant S3 API calls)
   - ❌ More complex scheduling logic

2. **S3 Event Notifications**: Direct S3 → webhook notifications
   - ❌ Requires public webhook endpoint with S3-specific handling
   - ❌ Less reliable than SNS (no retry mechanism)
   - ❌ Limited filtering options

3. **Manual Processing**: Process emails on-demand only
   - ❌ No automation
   - ❌ Requires manual intervention

**Why SNS Is Optimal:**
- ⚡ **Real-time**: Notifications sent within seconds
- 🔄 **Reliable**: Built-in retry mechanism
- 💰 **Cost-effective**: Pay only for notifications sent
- 🔒 **Secure**: Confirmed subscriptions prevent abuse
- 📊 **Scalable**: Handles high email volumes efficiently

### 4. **Subscription Response** (Response Handler)
- **Purpose**: Sends confirmation response back to AWS SNS
- **Response**: "Subscription confirmed"
- **Trigger**: After successful subscription confirmation

This completes the handshake with AWS and enables the real-time email processing pipeline.

### 5. **Is Email Notification?** (Email Router)
- **Purpose**: Validates that the SNS message is an email notification
- **Condition**: Checks if `$json.Type == "Notification"`
- **Logic**: Ensures we're processing actual email events

### 6. **Parse Email Metadata** (Data Extraction)
- **Purpose**: Extracts email metadata from SNS notification
- **Input**: SNS Message containing SES notification
- **Output**: Structured email data including:
  - `messageId`: Unique email identifier
  - `timestamp`: When email was received
  - `source`: Sender email address
  - `destination`: Recipient email addresses
  - `commonHeaders`: Standard email headers
  - `s3Bucket`: S3 bucket name storing the email
  - `s3ObjectKey`: S3 object key for email file

### 7. **Download Email from S3** (Content Retrieval)
- **Purpose**: Downloads the actual email content from S3 storage
- **Authentication**: Uses AWS credentials configured in n8n
- **URL**: `https://{s3Bucket}.s3.amazonaws.com/{s3ObjectKey}`
- **Output**: Raw email content (headers + body)

### 8. **Parse Email Content** (Email Parser)
- **Purpose**: Parses raw email into structured data
- **Process**:
  1. Splits email into headers and body
  2. Parses email headers (From, To, Subject, Date, etc.)
  3. Handles multi-line header continuation
  4. Extracts email body content
- **Output**: Structured email object with:
  - `from`: Sender address
  - `to`: Recipient address
  - `subject`: Email subject line
  - `date`: Email date
  - `body`: Email body content
  - `headers`: All email headers
  - `rawContent`: Original email content

### 9. **Process Email Logic** (Business Logic)
- **Purpose**: Custom business logic for email processing
- **Current Logic**:
  - Logs email details to console
  - Creates summary of processed email
- **Customization Points**:
  - Add keyword detection (invoice, support, etc.)
  - Integrate with external systems
  - Extract specific data patterns
  - Trigger different workflows based on content

### 10. **Success Response** (Completion)
- **Purpose**: Sends success response back to AWS SNS
- **Response**: "Email processed successfully"
- **Trigger**: After email processing is complete

## Data Flow

### SNS Subscription Confirmation Flow
```
Webhook → Is Subscription Confirmation? (TRUE)
    ↓
Confirm Subscription → Subscription Response
```

### Email Processing Flow
```
Webhook → Is Subscription Confirmation? (FALSE)
    ↓
Is Email Notification? (TRUE)
    ↓
Parse Email Metadata
    ↓
Download Email from S3
    ↓
Parse Email Content
    ↓
Process Email Logic
    ↓
Success Response
```

## Configuration Requirements

### AWS Prerequisites
1. **SES Domain Verification**: `arrgh.paulbonneville.com` verified in AWS SES
2. **MX Record**: DNS MX record pointing to AWS SES inbound endpoints
3. **S3 Bucket**: `n8n-inbound-emails-production` for email storage
4. **SNS Topic**: For real-time notifications to n8n
5. **IAM Permissions**: n8n needs S3 read access

### n8n Configuration
1. **AWS Credentials**: Configured in n8n for S3 access
2. **Webhook Endpoint**: Publicly accessible at the configured URL
3. **Workflow Activation**: Workflow must be active to receive webhooks

## Customization Guide

### Adding Business Logic
Modify the **"Process Email Logic"** node to add custom processing:

```javascript
// Example: Invoice processing
const bodyText = $json.body.toLowerCase();
if (bodyText.includes('invoice')) {
  // Extract invoice number, amount, etc.
  const invoiceMatch = bodyText.match(/invoice[:\s#]*(\w+)/i);
  const amountMatch = bodyText.match(/\$([0-9,]+\.?\d*)/);
  
  return {
    type: 'invoice',
    invoiceNumber: invoiceMatch ? invoiceMatch[1] : null,
    amount: amountMatch ? amountMatch[1] : null,
    processed: true
  };
}

// Example: Support ticket processing
if (bodyText.includes('support') || bodyText.includes('help')) {
  return {
    type: 'support_ticket',
    priority: bodyText.includes('urgent') ? 'high' : 'normal',
    processed: true
  };
}
```

### Adding External Integrations
Add new nodes after **"Process Email Logic"** to integrate with:
- CRM systems (Salesforce, HubSpot)
- Ticketing systems (Jira, ServiceNow)
- Databases (PostgreSQL, MongoDB)
- APIs (Slack, Teams, custom endpoints)

## Monitoring and Debugging

### Execution Logs
- View workflow executions in n8n interface
- Check individual node outputs for debugging
- Monitor processing times and error rates

### AWS Monitoring
- **S3 Bucket**: Check for email storage
- **SNS Topic**: Monitor message delivery metrics
- **SES**: Review email reception statistics

### Common Issues
1. **Webhook not triggering**: Check SNS subscription status
2. **S3 download fails**: Verify AWS credentials and permissions
3. **Email parsing errors**: Check email format and encoding
4. **Missing emails**: Verify SES receipt rules and domain verification

## Security Considerations

### Data Privacy
- Emails are stored in S3 with lifecycle policy (30-day retention)
- Only necessary email metadata is extracted and processed
- Sensitive content should be handled according to privacy requirements

### Access Control
- AWS credentials have minimal required permissions (S3 read-only)
- Webhook endpoint should use HTTPS
- Consider adding webhook authentication for production use

### Compliance
- Email processing may be subject to data protection regulations
- Implement appropriate data retention and deletion policies
- Log processing activities for audit trails

## Performance Optimization

### Scaling Considerations
- Current setup handles moderate email volumes
- For high volume, consider:
  - Multiple webhook endpoints
  - Queue-based processing
  - Database storage for processed emails

### Cost Optimization
- S3 lifecycle policies automatically delete old emails
- SNS charges per notification (minimal cost)
- Monitor AWS usage for unexpected charges

## Testing

### Test Email Processing
Send test emails to any address at `@arrgh.paulbonneville.com`:
```bash
echo "Test email content" | mail -s "Test Subject" test@arrgh.paulbonneville.com
```

### Webhook Testing
Use the provided test script:
```bash
./test-sns-webhook.sh test
```

## Troubleshooting

### Workflow Not Triggering
1. Check SNS subscription is confirmed
2. Verify webhook URL is accessible
3. Ensure workflow is active

### Email Processing Failures
1. Check S3 bucket permissions
2. Verify AWS credentials in n8n
3. Review email content for parsing issues

### Performance Issues
1. Monitor S3 download times
2. Check n8n resource usage
3. Optimize email parsing logic if needed