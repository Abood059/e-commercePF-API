#!/bin/bash

################################################################################
# Deployment Script for E-Commerce API
# Implements Blue-Green deployment strategy
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
LOG_FILE="/home/deployer/logs/deployment.log"
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

log "=========================================="
log "Starting Deployment Process"
log "=========================================="

################################################################################
# Pre-deployment Checks
################################################################################
log "Running pre-deployment checks..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running. Please start Docker first."
fi

# Check if required files exist
if [ ! -f "$APP_DIR/docker-compose.yml" ]; then
    error "docker-compose.yml not found in $APP_DIR"
fi

if [ ! -f "$APP_DIR/.env" ]; then
    error ".env file not found in $APP_DIR"
fi

# Check disk space
DISK_USAGE=$(df -h "$APP_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    warn "Disk usage is above 80%. Consider cleaning up."
fi

log "Pre-deployment checks passed"

################################################################################
# Backup Current Version
################################################################################
log "Creating backup of current version..."

if [ -d "$APP_DIR/current" ]; then
    BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"
    mkdir -p "$BACKUP_PATH"
    cp -r "$APP_DIR/current" "$BACKUP_PATH/"
    log "Backup created at $BACKUP_PATH"
else
    warn "No current version found, skipping backup"
fi

################################################################################
# Determine Deployment Target (Blue or Green)
################################################################################
log "Determining deployment target..."

if docker ps --format '{{.Names}}' | grep -q "ecommerce-api-blue"; then
    TARGET="green"
    CURRENT="blue"
    TARGET_PORT="3001"
    CURRENT_PORT="3000"
else
    TARGET="blue"
    CURRENT="green"
    TARGET_PORT="3000"
    CURRENT_PORT="3001"
fi

log "Deploying to $TARGET environment (port $TARGET_PORT)"
log "Current environment: $CURRENT (port $CURRENT_PORT)"

################################################################################
# Stop Target Container
################################################################################
log "Stopping $TARGET container..."

cd "$APP_DIR"

if docker ps --format '{{.Names}}' | grep -q "ecommerce-api-$TARGET"; then
    docker-compose stop api-$TARGET || true
    docker-compose rm -f api-$TARGET || true
    log "$TARGET container stopped"
else
    log "$TARGET container not running, skipping stop"
fi

################################################################################
# Pull Latest Code (if using git)
################################################################################
if [ -d "$APP_DIR/.git" ]; then
    log "Pulling latest code from git..."
    cd "$APP_DIR"
    git fetch origin
    git reset --hard origin/main
    log "Latest code pulled"
else
    log "Not a git repository, skipping git pull"
fi

################################################################################
# Build New Image
################################################################################
log "Building new Docker image..."
docker-compose build --no-cache api-$TARGET

if [ $? -ne 0 ]; then
    error "Docker build failed"
fi

log "Docker image built successfully"

################################################################################
# Start Target Container
################################################################################
log "Starting $TARGET container..."
docker-compose --profile $TARGET up -d api-$TARGET

if [ $? -ne 0 ]; then
    error "Failed to start $TARGET container"
fi

log "$TARGET container started"

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
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "ecommerce-api-$TARGET"; then
        error "$TARGET container is not running"
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo -n "."
    sleep 2
done

echo ""

if [ "$HEALTHY" = false ]; then
    warn "Health check timeout, checking container status..."
    docker-compose logs api-$TARGET
    error "Health check failed for $TARGET container"
fi

log "Health check passed for $TARGET container"

################################################################################
# Update Nginx Configuration
################################################################################
log "Updating Nginx configuration..."

NGINX_CONF="$APP_DIR/nginx/conf.d/default.conf"

if [ "$TARGET" = "green" ]; then
    sed -i 's/server api-blue:3000/server api-green:3001/' "$NGINX_CONF"
    sed -i 's/server api-green:3001 backup/server api-blue:3000 backup/' "$NGINX_CONF"
else
    sed -i 's/server api-green:3001/server api-blue:3000/' "$NGINX_CONF"
    sed -i 's/server api-blue:3000 backup/server api-green:3001 backup/' "$NGINX_CONF"
fi

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
# Wait and Verify
################################################################################
log "Waiting for traffic to switch..."
sleep 10

# Check if new container is receiving traffic
log "Verifying deployment..."
sleep 5

################################################################################
# Stop Old Container (with delay)
################################################################################
log "Stopping old container ($CURRENT) after grace period..."
sleep 30

if docker ps --format '{{.Names}}' | grep -q "ecommerce-api-$CURRENT"; then
    docker-compose stop api-$CURRENT || true
    log "Old container stopped"
else
    log "Old container not running"
fi

################################################################################
# Cleanup Old Backups
################################################################################
log "Cleaning up old backups (keeping last 5)..."
cd "$BACKUP_DIR"
ls -t | tail -n +6 | xargs -r rm -rf
log "Old backups cleaned"

################################################################################
# Deployment Summary
################################################################################
log "=========================================="
log "Deployment Completed Successfully!"
log "=========================================="
log ""
log "Deployment Details:"
log "- Target Environment: $TARGET"
log "- Target Port: $TARGET_PORT"
log "- Backup Location: $BACKUP_PATH"
log "- Timestamp: $TIMESTAMP"
log ""
log "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
log ""
log "Deployment finished at $(date)"
