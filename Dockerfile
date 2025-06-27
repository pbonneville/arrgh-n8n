FROM n8nio/n8n:latest

# Create the .n8n directory with proper permissions
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# Set the working directory
WORKDIR /home/node

# Just add env debug at runtime
CMD ["sh", "-c", "echo '=== Database Environment Variables ==='; env | grep -E 'DB_|N8N_' | sort; echo '=== Starting n8n ==='; n8n"]
