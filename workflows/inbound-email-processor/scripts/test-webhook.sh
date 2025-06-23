#!/bin/bash

echo "=== Testing n8n Webhook Endpoint ==="
echo
echo "1. Testing basic connectivity..."
curl -X POST https://n8n.paulbonneville.com/webhook/inbound-email \
  -H "Content-Type: application/json" \
  -d '{"test": "basic connectivity"}' \
  -w "Response Code: %{http_code}\n" \
  -s -o /dev/null

echo
echo "2. Testing SNS subscription confirmation format..."
curl -X POST https://n8n.paulbonneville.com/webhook/inbound-email \
  -H "Content-Type: text/plain" \
  -d '{
    "Type": "SubscriptionConfirmation",
    "MessageId": "test-message-id",
    "Token": "test-token",
    "TopicArn": "arn:aws:sns:us-west-2:944355535974:n8n-email-notifications-production",
    "Message": "Test subscription confirmation",
    "SubscribeURL": "https://example.com/test-confirm",
    "Timestamp": "2025-06-23T08:00:00.000Z"
  }' \
  -w "Response Code: %{http_code}\n" \
  -s -o /dev/null

echo
echo "3. Check if webhook path is correct..."
echo "Expected path: /webhook/inbound-email"
echo "Full URL: https://n8n.paulbonneville.com/webhook/inbound-email"
echo
echo "If tests pass but subscription doesn't confirm:"
echo "- Check n8n workflow is activated"
echo "- Verify webhook node path matches exactly"
echo "- Check n8n execution logs for errors"