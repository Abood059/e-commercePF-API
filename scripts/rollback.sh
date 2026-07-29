#!/bin/bash

################################################################################
# Rollback Script for E-Commerce API
# Reverts to the previous backup version
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
APP_DIR="/home/deployer/ecommerce-api"
BACKUP_DIR="/home/deployer/backups"
LOG_FILE="/home/deployer/logs/rollback.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as deployer
if [ "$(whoami)" != "deployer" ]; then
    error "This script must be run as deployer user"
fi

# Check for backup argument
if [ -z "$1" ]; then
    log "=========================================="
    log "Available Backups:"
    log "=========================================="
    ls -lt "$BACKUP_DIR" | grep "^d" | awk '{print $9}' | grep -v "^\.$" | grep -v "^\.\.$" | head -10
    log ""
    log "Usage: $0 <backup_name>"
    log "Example: $0 backup_20240129_120000"
    exit 1
fi

BACKUP_NAME="$1"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

log "=========================================="
log "Starting Rollback Process"
log "=========================================="
log "Rollback to: $BACKUP_NAME"

################################################################################
# Pre-rollback Checks
################################################################################
log "Running pre-rollback checks..."

# Check if backup exists
if [ ! -d "$BACKUP_PATH" ]; then
    error "Backup $BACKUP_NAME not found in $BACKUP_DIR"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running. Please start Docker first."
fi

log "Pre-rollback checks passed"

################################################################################
# Create Backup of Current State
################################################################################
log "Creating emergency backup of current state..."
EMERGENCY_BACKUP="$BACKUP_DIR/emergency_rollback_$TIMESTAMP"
mkdir -p "$EMERGENCY_BACKUP"
cp -r "$APP_DIR/current" "$EMERGENCY_BACKUP/" 2>/dev/null || true
log "Emergency backup created at $EMERGENCY_BACKUP"

################################################################################
# Stop All Running Containers
################################################################################
log "Stopping all running containers..."
cd "$APP_DIR"

docker-compose stop api-blue api-green || true
docker-compose rm -f api-blue api-green || true

log "Containers stopped"

################################################################################
# Restore from Backup
################################################################################
log "Restoring from backup..."
rm -rf "$APP_DIR/current"
cp -r "$BACKUP_PATH/current" "$APP_DIR/current"

log "Backup restored"

################################################################################
# Start Blue Container
################################################################################
log "Starting blue container..."
cd "$APP_DIR/current"
docker-compose up -d api-blue

if [ $? -ne 0 ]; then
    error "Failed to start blue container"
fi

log "Blue container started"

################################################################################
# Wait for Health Check
################################################################################
log "Waiting for health check..."
MAX_RETRIES=30
RETRY_COUNT=0
HEALTHY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker ps --format '{{.Health}}' | grep -q "healthy"; then
        HEALTHY=true
        break
    fi
    
    if ! docker ps --format '{{.Names}}' | grep -q "ecommerce-api-blue"; then
        error "Blue container is not running"
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo -n "."
    sleep 2
done

echo ""

if [ "$HEALTHY" = false ]; then
    warn "Health check timeout, checking container status..."
    docker-compose logs api-blue
    error "Health check failed for blue container"
fi

log "Health check passed"

################################################################################
# Update Nginx to Point to Blue
################################################################################
log "Updating Nginx configuration to point to blue..."
NGINX_CONF="$APP_DIR/nginx/conf.d/default.conf"
sed -i 's/server api-green:3001/server api-blue:3000/' "$NGINX_CONF"
sed -i 's/server api-blue:3000 backup/server api-green:3001 backup/' "$NGINX_CONF"

log "Nginx configuration updated"

################################################################################
# Reload Nginx
################################################################################
log "Reloading Nginx..."
if docker-compose exec -T nginx nginx -t; then
    docker-compose exec -T nginx nginx -s reload || docker-compose restart nginx
    log "Nginx reloaded successfully"
else
    error "Nginx configuration test failed"
fi

################################################################################
# Rollback Summary
################################################################################
log "=========================================="
log "Rollback Completed Successfully!"
log "=========================================="
log ""
log "Rollback Details:"
log "- Restored from: $BACKUP_NAME"
log "- Emergency backup: $EMERGENCY_BACKUP"
log "- Timestamp: $TIMESTAMP"
log ""
log "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
log ""
log "Rollback finished at $(date)"
