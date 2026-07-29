#!/bin/bash

################################################################################
# MongoDB Restore Script for E-Commerce API
# Restores database from a backup file
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKUP_DIR="/home/deployer/backups/mongodb"
LOG_FILE="/home/deployer/logs/restore.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# MongoDB configuration
MONGO_CONTAINER="ecommerce-mongodb"
MONGO_USERNAME="admin"
MONGO_PASSWORD="${MONGO_PASSWORD:-}"
MONGO_DATABASE="ecommerce"

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

# Check for backup file argument
if [ -z "$1" ]; then
    log "=========================================="
    log "Available Backups:"
    log "=========================================="
    ls -lt "$BACKUP_DIR"/mongodb_backup_*.gz 2>/dev/null | awk '{print $9}' | head -10
    log ""
    log "Usage: $0 <backup_file>"
    log "Example: $0 mongodb_backup_20240129_120000.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Handle relative or absolute path
if [[ "$BACKUP_FILE" != /* ]]; then
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
fi

log "=========================================="
log "Starting MongoDB Restore"
log "=========================================="
log "Restore from: $BACKUP_FILE"

################################################################################
# Pre-restore Checks
################################################################################
log "Running pre-restore checks..."

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    error "Backup file not found: $BACKUP_FILE"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running"
fi

# Check if MongoDB container is running
if ! docker ps --format '{{.Names}}' | grep -q "$MONGO_CONTAINER"; then
    error "MongoDB container $MONGO_CONTAINER is not running"
fi

# Get MongoDB password from environment if not set
if [ -z "$MONGO_PASSWORD" ]; then
    if [ -f "/home/deployer/ecommerce-api/.env" ]; then
        MONGO_PASSWORD=$(grep "MONGO_PASSWORD" /home/deployer/ecommerce-api/.env | cut -d '=' -f2)
    else
        error "MongoDB password not found. Set MONGO_PASSWORD environment variable or ensure .env file exists."
    fi
fi

log "Pre-restore checks passed"

################################################################################
# Create Pre-Restore Backup
################################################################################
log "Creating pre-restore backup..."
PRE_RESTORE_BACKUP="$BACKUP_DIR/pre_restore_$TIMESTAMP"
docker exec "$MONGO_CONTAINER" mongodump \
    --username="$MONGO_USERNAME" \
    --password="$MONGO_PASSWORD" \
    --authenticationDatabase=admin \
    --db="$MONGO_DATABASE" \
    --archive=/tmp/pre_restore_$TIMESTAMP.gz \
    --gzip

docker cp "$MONGO_CONTAINER:/tmp/pre_restore_$TIMESTAMP.gz" "$PRE_RESTORE_BACKUP.gz"
docker exec "$MONGO_CONTAINER" rm -f /tmp/pre_restore_$TIMESTAMP.gz

log "Pre-restore backup created: $PRE_RESTORE_BACKUP.gz"

################################################################################
# Stop API Containers
################################################################################
log "Stopping API containers to prevent conflicts..."
cd /home/deployer/ecommerce-api
docker-compose stop api-blue api-green || true

log "API containers stopped"

################################################################################
# Perform Restore
################################################################################
log "Restoring database from backup..."

# Copy backup to container
docker cp "$BACKUP_FILE" "$MONGO_CONTAINER:/tmp/restore_backup.gz"

# Perform restore
docker exec "$MONGO_CONTAINER" mongorestore \
    --username="$MONGO_USERNAME" \
    --password="$MONGO_PASSWORD" \
    --authenticationDatabase=admin \
    --db="$MONGO_DATABASE" \
    --archive=/tmp/restore_backup.gz \
    --gzip

# Clean up
docker exec "$MONGO_CONTAINER" rm -f /tmp/restore_backup.gz

log "Database restored successfully"

################################################################################
# Restart API Containers
################################################################################
log "Restarting API containers..."
cd /home/deployer/ecommerce-api
docker-compose start api-blue || docker-compose up -d api-blue

log "API containers restarted"

################################################################################
# Verify Restore
################################################################################
log "Verifying restore..."
sleep 5

# Check if container is healthy
if docker ps --format '{{.Names}}' | grep -q "ecommerce-api-blue"; then
    log "API container is running"
else
    warn "API container may not be running properly"
fi

################################################################################
# Restore Summary
################################################################################
log "=========================================="
log "MongoDB Restore Completed Successfully!"
log "=========================================="
log ""
log "Restore Details:"
log "- Restored from: $BACKUP_FILE"
log "- Database: $MONGO_DATABASE"
log "- Pre-restore backup: $PRE_RESTORE_BACKUP.gz"
log "- Timestamp: $TIMESTAMP"
log ""
log "Restore finished at $(date)"
log ""
log "Note: If there are any issues, you can restore using the pre-restore backup:"
log "  $0 $PRE_RESTORE_BACKUP.gz"
