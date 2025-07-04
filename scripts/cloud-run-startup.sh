#!/bin/bash

# Cloud Run startup script for n8n
# Handles port binding and environment setup

set -e

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

log "🚀 Starting n8n for Cloud Run..."

# Cloud Run provides PORT environment variable
if [ -z "$PORT" ]; then
    warn "PORT environment variable not set, using default 5678"
    export PORT=5678
fi

log "Using port: $PORT"

# Set n8n port to match Cloud Run port
export N8N_PORT=$PORT

# Ensure required environment variables are set
if [ -z "$N8N_HOST" ]; then
    export N8N_HOST="0.0.0.0"
fi

if [ -z "$N8N_PROTOCOL" ]; then
    export N8N_PROTOCOL="https"
fi

# Log key configuration
log "Configuration:"
log "  N8N_HOST: $N8N_HOST"
log "  N8N_PORT: $N8N_PORT"
log "  N8N_PROTOCOL: $N8N_PROTOCOL"
log "  WEBHOOK_URL: $WEBHOOK_URL"

# Validate database connection
if [ -n "$DB_POSTGRESDB_HOST" ]; then
    log "Database configured: $DB_POSTGRESDB_HOST"
else
    error "Database configuration missing!"
    exit 1
fi

# Setup n8n for Cloud Run health checks
setup_health_checks() {
    log "Configuring n8n for Cloud Run health checks..."
    
    # n8n serves its web interface at / which acts as a health check
    # Additional CORS configuration for cloud environments
    export N8N_ADDITIONAL_CORS_ORIGINS="*"
    
    log "Health checks will use n8n's built-in web interface at /"
}

# Trap signals for graceful shutdown
trap 'log "Received shutdown signal, stopping n8n..."; kill -TERM $PID; wait $PID' SIGTERM SIGINT

# Setup health checks
setup_health_checks

log "🎯 Starting n8n server..."

# Start n8n with proper signal handling
exec n8n start &
PID=$!

# Wait for n8n to start
log "Waiting for n8n to be ready..."
sleep 10

# Check if n8n is responding at root path
if curl -f "http://localhost:$PORT/" >/dev/null 2>&1; then
    log "✅ n8n web interface is responding - healthy"
else
    warn "n8n web interface not yet ready, but continuing startup..."
fi

log "🎉 n8n startup complete!"

# Keep the script running
wait $PID