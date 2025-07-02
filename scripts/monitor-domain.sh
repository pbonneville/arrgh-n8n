#!/bin/bash

# Monitor domain migration progress
echo "🔍 Monitoring n8n.paulbonneville.com migration to Cloud Run..."
echo "=================================================="

while true; do
    echo -e "\n📅 $(date)"
    
    # Check DNS
    echo -e "\n🌐 DNS Status:"
    CNAME=$(dig n8n.paulbonneville.com CNAME +short)
    echo "CNAME: $CNAME"
    
    # Check certificate status
    echo -e "\n🔐 Certificate Status:"
    STATUS=$(gcloud beta run domain-mappings describe \
        --domain n8n.paulbonneville.com \
        --region us-central1 \
        --format="value(status.conditions[0].message)" 2>/dev/null)
    echo "$STATUS"
    
    # Try to access the site
    echo -e "\n🌍 Testing HTTPS Access:"
    if curl -I https://n8n.paulbonneville.com --max-time 5 -s | grep -q "HTTP/2 200"; then
        HEADERS=$(curl -I https://n8n.paulbonneville.com --max-time 5 -s)
        if echo "$HEADERS" | grep -q "x-render-origin-server"; then
            echo "⚠️  Still serving from Render"
        elif echo "$HEADERS" | grep -q "server: Google Frontend"; then
            echo "✅ Now serving from Cloud Run!"
            echo -e "\n🎉 Migration complete! Your n8n instance is now accessible at:"
            echo "https://n8n.paulbonneville.com"
            break
        else
            echo "🔄 Service is responding but origin unclear"
        fi
    else
        echo "⏳ HTTPS not yet available (certificate provisioning)"
    fi
    
    echo -e "\n⏰ Checking again in 60 seconds... (Press Ctrl+C to stop)"
    sleep 60
done