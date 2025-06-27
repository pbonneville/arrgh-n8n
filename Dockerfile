FROM n8nio/n8n:latest

# Create the .n8n directory with proper permissions
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# Add debug script to show environment variables
RUN echo '#!/bin/bash' > /debug-env.sh && \
    echo 'echo "=== Database Environment Variables ===" ' >> /debug-env.sh && \
    echo 'env | grep -E "DB_|N8N_" | sort' >> /debug-env.sh && \
    echo 'echo "=== Starting n8n ===" ' >> /debug-env.sh && \
    echo 'exec "$@"' >> /debug-env.sh && \
    chmod +x /debug-env.sh

# Set the working directory
WORKDIR /home/node

# Use debug script as entrypoint
ENTRYPOINT ["/debug-env.sh"]
