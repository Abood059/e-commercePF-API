#!/bin/bash

################################################################################
# Cron Job Setup Script for E-Commerce API
# Configures automated tasks for backup and maintenance
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as deployer
if [ "$(whoami)" != "deployer" ]; then
    error "This script must be run as deployer user"
fi

log "=========================================="
log "Setting Up Cron Jobs"
log "=========================================="

################################################################################
# Create Log Directories
################################################################################
log "Creating log directories..."
mkdir -p /home/deployer/logs
mkdir -p /home/deployer/ecommerce-api/scripts

################################################################################
# Create Cron File
################################################################################
log "Creating cron configuration..."

CRON_FILE="/tmp/deployer_cron_$USER"
cat > "$CRON_FILE" << 'EOF'
# MongoDB backup - Every Sunday at 2 AM
0 2 * * 0 /home/deployer/ecommerce-api/scripts/backup-mongodb.sh >> /home/deployer/logs/backup.log 2>&1

# Docker system cleanup - Every day at 3 AM
0 3 * * * docker system prune -f --volumes >> /home/deployer/logs/docker-cleanup.log 2>&1

# Log rotation - Every day at 4 AM
0 4 * * * find /home/deployer/ecommerce-api/logs -name "*.log" -mtime +7 -delete >> /home/deployer/logs/log-cleanup.log 2>&1

# Backup cleanup - Every day at 5 AM (keep last 30 days)
0 5 * * * find /home/deployer/backups/mongodb -name "mongodb_backup_*.gz" -mtime +30 -delete >> /home/deployer/logs/backup-cleanup.log 2>&1

# Health check - Every 15 minutes
*/15 * * * * curl -f http://localhost/health >> /home/deployer/logs/health-check.log 2>&1 || echo "Health check failed at $(date)" >> /home/deployer/logs/health-check.log 2>&1
EOF

################################################################################
# Install Cron Jobs
################################################################################
log "Installing cron jobs..."
crontab "$CRON_FILE"
rm "$CRON_FILE"

log "Cron jobs installed successfully"

################################################################################
# Display Current Cron Jobs
################################################################################
log "=========================================="
log "Current Cron Jobs:"
log "=========================================="
crontab -l

log "=========================================="
log "Cron Setup Completed!"
log "=========================================="
