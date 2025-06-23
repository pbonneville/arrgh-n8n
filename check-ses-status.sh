#!/bin/bash

echo "=== Checking SES Domain Verification Status ==="
echo

# Check domain verification
echo "Domain Verification Status:"
aws ses get-identity-verification-attributes --identities paulbonneville.com --region us-west-2 | jq -r '.VerificationAttributes."paulbonneville.com".VerificationStatus'

echo
echo "DNS TXT Record Check:"
dig TXT _amazonses.paulbonneville.com +short || echo "Not found yet"

echo
echo "DKIM Verification Status:"
aws ses get-identity-dkim-attributes --identities paulbonneville.com --region us-west-2 | jq -r '.DkimAttributes."paulbonneville.com"'

echo
echo "=== SES Account Status ==="
echo "Sending Quota:"
aws ses get-send-quota --region us-west-2 | jq '.'

echo
echo "If domain shows as 'Verified', you can deploy to n8n!"