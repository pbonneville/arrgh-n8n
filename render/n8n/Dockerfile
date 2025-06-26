FROM n8nio/n8n:latest

# Set the user to root for installation (if needed)
USER root

# Install any additional dependencies if needed
# RUN apk add --no-cache <package-name>

# Create the .n8n directory with proper permissions
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# Switch back to the node user
USER node

# Set the working directory
WORKDIR /home/node

# Expose the n8n port
EXPOSE 5678

# Start n8n
CMD ["n8n", "start"]