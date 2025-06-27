FROM n8nio/n8n:latest

# Create the .n8n directory with proper permissions
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# Add debug script to show environment variables
COPY <<EOF /debug-env.sh
#!/bin/bash
echo "=== Database Environment Variables ==="
env | grep -E "DB_|N8N_" | sort
echo "=== Starting n8n ==="
exec "\$@"
EOF

RUN chmod +x /debug-env.sh

# Set the working directory
WORKDIR /home/node

# Use debug script as entrypoint
ENTRYPOINT ["/debug-env.sh"]
