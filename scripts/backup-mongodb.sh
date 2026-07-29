#!/bin/bash

################################################################################
# MongoDB Backup Script for E-Commerce API
# Performs automated backups with compression and rotation
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKUP_DIR="/home/deployer/backups/mongodb"
LOG_FILE="/home/deployer/logs/backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# MongoDB configuration (from docker-compose)
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

log "=========================================="
log "Starting MongoDB Backup"
log "=========================================="

################################################################################
# Pre-backup Checks
################################################################################
log "Running pre-backup checks..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running"
fi

# Check if MongoDB container is running
if ! docker ps --format '{{.Names}}' | grep -q "$MONGO_CONTAINER"; then
    error "MongoDB container $MONGO_CONTAINER is not running"
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

log "Pre-backup checks passed"

################################################################################
# Create Backup
################################################################################
log "Creating MongoDB backup..."

BACKUP_FILE="$BACKUP_DIR/mongodb_backup_$TIMESTAMP"
TEMP_DIR="/tmp/mongodb_backup_$TIMESTAMP"
mkdir -p "$TEMP_DIR"

# Get MongoDB password from environment if not set
if [ -z "$MONGO_PASSWORD" ]; then
    if [ -f "/home/deployer/ecommerce-api/.env" ]; then
        MONGO_PASSWORD=$(grep "MONGO_PASSWORD" /home/deployer/ecommerce-api/.env | cut -d '=' -f2)
    else
        error "MongoDB password not found. Set MONGO_PASSWORD environment variable or ensure .env file exists."
    fi
fi

# Perform backup using mongodump
docker exec "$MONGO_CONTAINER" mongodump \
    --username="$MONGO_USERNAME" \
    --password="$MONGO_PASSWORD" \
    --authenticationDatabase=admin \
    --db="$MONGO_DATABASE" \
    --archive=/tmp/mongodb_backup_$TIMESTAMP.gz \
    --gzip

# Copy backup from container to host
docker cp "$MONGO_CONTAINER:/tmp/mongodb_backup_$TIMESTAMP.gz" "$BACKUP_FILE.gz"

# Clean up temporary files in container
docker exec "$MONGO_CONTAINER" rm -f /tmp/mongodb_backup_$TIMESTAMP.gz

# Verify backup file
if [ ! -f "$BACKUP_FILE.gz" ]; then
    error "Backup file was not created"
fi

# Get backup size
BACKUP_SIZE=$(du -h "$BACKUP_FILE.gz" | cut -f1)

log "Backup created successfully: $BACKUP_FILE.gz ($BACKUP_SIZE)"

################################################################################
# Test Backup Integrity
################################################################################
log "Testing backup integrity..."

if gzip -t "$BACKUP_FILE.gz"; then
    log "Backup integrity test passed"
else
    error "Backup integrity test failed"
fi

################################################################################
# Cleanup Old Backups
################################################################################
log "Cleaning up old backups (older than $RETENTION_DAYS days)..."

find "$BACKUP_DIR" -name "mongodb_backup_*.gz" -mtime +$RETENTION_DAYS -delete

# Count remaining backups
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/mongodb_backup_*.gz 2>/dev/null | wc -l)
log "Remaining backups: $BACKUP_COUNT"

################################################################################
# Backup Summary
################################################################################
log "=========================================="
log "MongoDB Backup Completed Successfully!"
log "=========================================="
log ""
log "Backup Details:"
log "- Backup File: $BACKUP_FILE.gz"
log "- Size: $BACKUP_SIZE"
log "- Database: $MONGO_DATABASE"
log "- Timestamp: $TIMESTAMP"
log "- Retention: $RETENTION_DAYS days"
log ""
log "Backup finished at $(date)"
