#!/bin/bash

# Test SNS Webhook Script
# This script simulates various SNS payloads to test the n8n webhook

echo "=== SNS Webhook Test Script ==="
echo

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load environment variables if .env file exists
if [ -f "../local-development/.env" ]; then
    set -a  # automatically export all variables
    source ../local-development/.env
    set +a  # stop automatically exporting
fi

# Webhook URLs (use environment variables or defaults)
WEBHOOK_TEST_URL="${WEBHOOK_TEST_URL:-https://your-n8n-instance.com/webhook-test/inbound-email}"
WEBHOOK_PROD_URL="${WEBHOOK_PROD_URL:-https://your-n8n-instance.com/webhook/inbound-email}"

# Function to send test payload
send_test() {
    local test_name=$1
    local url=$2
    local message_type=$3
    local payload=$4
    
    echo -e "${YELLOW}Testing: $test_name${NC}"
    echo "URL: $url"
    echo "Message Type: $message_type"
    echo
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: text/plain" \
        -H "x-amz-sns-message-type: $message_type" \
        -H "x-amz-sns-message-id: test-$(date +%s)" \
        -H "x-amz-sns-topic-arn: ${SNS_TOPIC_ARN:-arn:aws:sns:region:account:email-notifications-topic}" \
        -d "$payload")
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ Success (HTTP $response)${NC}"
    else
        echo -e "${RED}✗ Failed (HTTP $response)${NC}"
    fi
    echo
}

# Test 1: Subscription Confirmation (for webhook-test endpoint)
if [ "$1" = "test" ] || [ "$1" = "confirm" ]; then
    PAYLOAD_CONFIRM='{
  "Type": "SubscriptionConfirmation",
  "MessageId": "12345678-1234-1234-1234-123456789012",
  "Token": "test-token-12345",
  "TopicArn": "${SNS_TOPIC_ARN:-arn:aws:sns:region:account:email-notifications-topic}",
  "Message": "You have chosen to subscribe to the topic arn:aws:sns:us-west-2:944355535974:n8n-email-notifications-production.\nTo confirm the subscription, visit the SubscribeURL included in this message.",
  "SubscribeURL": "https://sns.us-west-2.amazonaws.com/?Action=ConfirmSubscription&TopicArn=arn:aws:sns:us-west-2:944355535974:n8n-email-notifications-production&Token=test-token-12345",
  "Timestamp": "2025-06-23T10:00:00.000Z",
  "SignatureVersion": "1",
  "Signature": "test-signature",
  "SigningCertURL": "https://sns.us-west-2.amazonaws.com/SimpleNotificationService-test.pem"
}'
    
    send_test "Subscription Confirmation" "$WEBHOOK_TEST_URL" "SubscriptionConfirmation" "$PAYLOAD_CONFIRM"
fi

# Test 2: Email Notification (simulating an actual email)
if [ "$1" = "test" ] || [ "$1" = "email" ]; then
    PAYLOAD_EMAIL='{
  "Type": "Notification",
  "MessageId": "email-12345678-1234-1234-1234-123456789012",
  "TopicArn": "${SNS_TOPIC_ARN:-arn:aws:sns:region:account:email-notifications-topic}",
  "Subject": "Message published to SNS topic",
  "Message": "{\"notificationType\":\"Received\",\"mail\":{\"timestamp\":\"2025-06-23T15:00:00.000Z\",\"source\":\"${TEST_EMAIL_SENDER:-test@example.com}\",\"messageId\":\"test-email-id\",\"destination\":[\"${TEST_EMAIL_GENERAL:-test@your-subdomain.yourdomain.com}\"],\"commonHeaders\":{\"from\":[\"Test User <${TEST_EMAIL_SENDER:-test@example.com}>\"],\"to\":[\"${TEST_EMAIL_GENERAL:-test@your-subdomain.yourdomain.com}\"],\"subject\":\"Test Email\",\"date\":\"Mon, 23 Jun 2025 15:00:00 +0000\"}},\"receipt\":{\"action\":{\"type\":\"S3\",\"bucketName\":\"${AWS_S3_BUCKET:-your-email-storage-bucket}\",\"objectKey\":\"emails/test-email-object-key\"}}}",
  "Timestamp": "2025-06-23T15:00:00.000Z",
  "SignatureVersion": "1",
  "Signature": "test-signature",
  "SigningCertURL": "https://sns.us-west-2.amazonaws.com/SimpleNotificationService-test.pem",
  "UnsubscribeURL": "https://sns.us-west-2.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=test"
}'
    
    send_test "Email Notification" "$WEBHOOK_TEST_URL" "Notification" "$PAYLOAD_EMAIL"
fi

# Test 3: Production webhook test (be careful with this)
if [ "$1" = "prod" ]; then
    echo -e "${RED}WARNING: Testing production webhook${NC}"
    echo "This will create actual executions in your workflow"
    read -p "Are you sure? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        send_test "Production Webhook Test" "$WEBHOOK_PROD_URL" "Notification" "$PAYLOAD_EMAIL"
    else
        echo "Cancelled"
    fi
fi

# Usage instructions
if [ -z "$1" ]; then
    echo "Usage:"
    echo "  ./test-sns-webhook.sh test     # Run all test webhook tests"
    echo "  ./test-sns-webhook.sh confirm  # Test subscription confirmation only"
    echo "  ./test-sns-webhook.sh email    # Test email notification only"
    echo "  ./test-sns-webhook.sh prod     # Test production webhook (careful!)"
    echo
    echo "Configuration:"
    echo "  Set up your .env file in ../local-development/.env with:"
    echo "  - WEBHOOK_TEST_URL and WEBHOOK_PROD_URL"
    echo "  - SNS_TOPIC_ARN"
    echo "  - TEST_EMAIL_* variables"
    echo "  - AWS_S3_BUCKET"
    echo
    echo "Note: Use the 'Listen for test event' button in n8n before running tests"
fi