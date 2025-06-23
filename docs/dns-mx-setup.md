# DNS MX Record Setup for SES Inbound Email

## Overview
To enable AWS SES to receive emails for your domain, you need to add MX records to your DNS configuration.

## Required DNS Records

### MX Record
Add this MX record to your domain's DNS settings for the subdomain:

```
Type: MX
Name: arrgh (or arrgh.paulbonneville.com)
Value: 10 inbound-smtp.us-west-2.amazonaws.com
Priority: 10
TTL: 300 (or your DNS provider's default)
```

### Subdomain Support (Optional)
If you want to receive emails for specific subdomains (e.g., support@paulbonneville.com, noreply@paulbonneville.com), add:

```
Type: MX
Name: *
Value: 10 inbound-smtp.us-east-1.amazonaws.com
Priority: 10
TTL: 300
```

## DNS Provider Instructions

### Cloudflare
1. Log into Cloudflare dashboard
2. Select your domain (paulbonneville.com)
3. Go to DNS > Records
4. Click "Add record"
5. Select "MX" type
6. Name: @ (for root domain)
7. Mail server: inbound-smtp.us-east-1.amazonaws.com
8. Priority: 10
9. Click "Save"

### Google Domains / Google Cloud DNS
1. Go to Google Domains or Cloud DNS console
2. Select your domain
3. Click "DNS" or "Manage DNS"
4. Click "Add record"
5. Type: MX
6. Host: @ 
7. Data: 10 inbound-smtp.us-east-1.amazonaws.com
8. TTL: 300
9. Save

### Route 53 (if using AWS DNS)
1. Go to Route 53 console
2. Select your hosted zone
3. Click "Create record"
4. Record type: MX
5. Name: leave blank (for root domain)
6. Value: 10 inbound-smtp.us-east-1.amazonaws.com
7. TTL: 300
8. Create

## Verification

### Check MX Record
After adding the MX record, verify it's working:

```bash
# Check MX record
dig MX arrgh.paulbonneville.com

# Should return something like:
# arrgh.paulbonneville.com. 300 IN MX 10 inbound-smtp.us-west-2.amazonaws.com.
```

### Test Email Delivery
You can test email delivery using:

```bash
# Send test email (replace with your domain)
echo "Test email body" | mail -s "Test Subject" test@arrgh.paulbonneville.com
```

## Important Notes

1. **DNS Propagation**: MX record changes can take up to 48 hours to propagate globally, but usually take 5-30 minutes.

2. **Existing Email Service**: If you currently have email service (Gmail, Outlook, etc.) for this domain, adding MX records for SES will route ALL emails to SES instead. Make sure this is what you want.

3. **Backup MX Records**: Consider keeping a backup MX record with higher priority if you want fallback email handling:
   ```
   10 inbound-smtp.us-east-1.amazonaws.com
   20 your-backup-mail-server.com
   ```

4. **SPF Record**: Update your SPF record to include SES:
   ```
   Type: TXT
   Name: @
   Value: "v=spf1 include:amazonses.com ~all"
   ```

## Troubleshooting

### Common Issues
- **MX record not found**: Wait for DNS propagation (up to 48 hours)
- **Emails not being received**: Check SES receipt rules and S3 bucket permissions
- **Permission denied**: Ensure SES has proper IAM permissions to write to S3

### Verification Commands
```bash
# Check if MX record is set correctly
nslookup -type=MX arrgh.paulbonneville.com

# Check DNS propagation from different locations
dig @8.8.8.8 MX arrgh.paulbonneville.com
dig @1.1.1.1 MX arrgh.paulbonneville.com
```

## Next Steps

After DNS is configured:
1. Deploy the Terraform infrastructure
2. Import the n8n workflow
3. Test the complete email flow
4. Monitor CloudWatch logs for any issues