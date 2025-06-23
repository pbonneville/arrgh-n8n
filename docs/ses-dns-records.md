# AWS SES DNS Records Required

Add these DNS records to your domain (paulbonneville.com) to complete SES setup:

## Domain Verification (Required)
**TXT Record:**
- Name: `_amazonses.paulbonneville.com`
- Value: `UI4jdLDIquX/RtxrCAyspgckQ0wLAzrb78kVBTI6m/I=`

## DKIM Records (Recommended for better deliverability)
**CNAME Records:**

1. Name: `667x6cvxgsfd45nnlowwsfze5wdojk2f._domainkey.paulbonneville.com`
   - Value: `667x6cvxgsfd45nnlowwsfze5wdojk2f.dkim.amazonses.com`

2. Name: `ntmbuvoewjtl3hhxmkcin5ahu7eqvirj._domainkey.paulbonneville.com`
   - Value: `ntmbuvoewjtl3hhxmkcin5ahu7eqvirj.dkim.amazonses.com`

3. Name: `fizhgnch4g7jsqhxkyfffke42mpuxa7s._domainkey.paulbonneville.com`
   - Value: `fizhgnch4g7jsqhxkyfffke42mpuxa7s.dkim.amazonses.com`

## Verification Status
After adding these records, it may take up to 72 hours for DNS propagation, but typically verification happens within 15-30 minutes.

Check verification status:
```bash
aws ses get-identity-verification-attributes --identities paulbonneville.com --region us-west-2
```

## Next Steps
1. Add the DNS records above
2. Wait for domain verification
3. Request production access (move out of sandbox) if needed
4. Deploy the updated n8n configuration