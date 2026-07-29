#!/bin/bash

################################################################################
# VPS Setup Script for E-Commerce API
# This script initializes a DigitalOcean VPS for Docker deployment
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging
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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    error "Please run as root or with sudo"
fi

log "Starting VPS setup for E-Commerce API..."

################################################################################
# System Update
################################################################################
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y

################################################################################
# Install Essential Packages
################################################################################
log "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    ufw \
    fail2ban \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

################################################################################
# Install Docker
################################################################################
log "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Remove old versions
    apt-get remove -y docker docker-engine docker.io containerd runc || true
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    log "Docker installed successfully"
else
    log "Docker already installed"
fi

################################################################################
# Install Docker Compose
################################################################################
log "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log "Docker Compose installed successfully"
else
    log "Docker Compose already installed"
fi

################################################################################
# Create Deploy User
################################################################################
log "Setting up deploy user..."
if id "deployer" &>/dev/null; then
    log "User deployer already exists"
else
    useradd -m -s /bin/bash deployer
    log "User deployer created"
fi

# Add deployer to docker group
usermod -aG docker deployer

# Create SSH directory for deployer
mkdir -p /home/deployer/.ssh
chmod 700 /home/deployer/.ssh
chown deployer:deployer /home/deployer/.ssh

# Create application directories
mkdir -p /home/deployer/ecommerce-api
mkdir -p /home/deployer/backups
mkdir -p /home/deployer/logs
chown -R deployer:deployer /home/deployer

################################################################################
# Configure Firewall (UFW)
################################################################################
log "Configuring UFW Firewall..."

# Reset UFW to default
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow 22/tcp

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow application ports (for internal communication)
ufw allow 3000/tcp
ufw allow 3001/tcp

# Allow MongoDB (internal only - will be restricted by Docker networks)
ufw allow 27017/tcp

# Enable UFW
ufw --force enable

log "Firewall configured successfully"

################################################################################
# Configure Fail2Ban
################################################################################
log "Configuring Fail2Ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

systemctl enable fail2ban
systemctl start fail2ban

log "Fail2Ban configured successfully"

################################################################################
# SSH Hardening
################################################################################
log "Hardening SSH configuration..."

# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# SSH hardening settings
cat > /etc/ssh/sshd_config.d/security.conf << 'EOF'
# Disable root login
PermitRootLogin no

# Disable password authentication
PasswordAuthentication no

# Allow only key-based authentication
PubkeyAuthentication yes

# Disable empty passwords
PermitEmptyPasswords no

# Limit login attempts
MaxAuthTries 3

# Set login grace time
LoginGraceTime 60

# Disable X11 forwarding
X11Forwarding no

# Allow only specific users
AllowUsers deployer

# Use strong ciphers
Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-ctr,aes128-gcm@openssh.com,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256

# Ignore rhosts
IgnoreRhosts yes

# Disable host-based authentication
HostbasedAuthentication no

# Disable PAM
UsePAM no
EOF

# Restart SSH
systemctl restart sshd

log "SSH hardening completed"

################################################################################
# Docker System Optimization
################################################################################
log "Optimizing Docker configuration..."

# Create Docker daemon configuration
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF

# Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

log "Docker optimization completed"

################################################################################
# Setup Log Rotation
################################################################################
log "Setting up log rotation..."

cat > /etc/logrotate.d/docker-containers << 'EOF'
/home/deployer/ecommerce-api/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 deployer deployer
    sharedscripts
    postrotate
        docker-compose -f /home/deployer/ecommerce-api/docker-compose.yml restart > /dev/null 2>&1 || true
    endscript
}
EOF

log "Log rotation configured"

################################################################################
# Setup Cron Jobs
################################################################################
log "Setting up cron jobs for deployer user..."

# Create cron file for deployer
cat > /tmp/deployer_cron << 'EOF'
# MongoDB backup - Every Sunday at 2 AM
0 2 * * 0 /home/deployer/ecommerce-api/scripts/backup-mongodb.sh >> /home/deployer/logs/backup.log 2>&1

# Docker system cleanup - Every day at 3 AM
0 3 * * * docker system prune -f --volumes >> /home/deployer/logs/docker-cleanup.log 2>&1

# Log rotation - Every day at 4 AM
0 4 * * * find /home/deployer/ecommerce-api/logs -name "*.log" -mtime +7 -delete >> /home/deployer/logs/log-cleanup.log 2>&1
EOF

crontab -u deployer /tmp/deployer_cron
rm /tmp/deployer_cron

log "Cron jobs configured"

################################################################################
# System Tuning for Low Resources (1GB RAM)
################################################################################
log "Tuning system for low resources..."

# Reduce swap usage
sysctl vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf

# Optimize file descriptors
echo "* soft nofile 64000" >> /etc/security/limits.conf
echo "* hard nofile 64000" >> /etc/security/limits.conf

# Optimize TCP settings
cat >> /etc/sysctl.conf << 'EOF'
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_syn_backlog = 2048
net.core.somaxconn = 1024
EOF

sysctl -p

log "System tuning completed"

################################################################################
# Final Setup
################################################################################
log "Creating directory structure..."
mkdir -p /home/deployer/ecommerce-api/scripts
mkdir -p /home/deployer/ecommerce-api/nginx/conf.d
mkdir -p /home/deployer/ecommerce-api/nginx/logs
mkdir -p /home/deployer/backups/mongodb
mkdir -p /home/deployer/logs

chown -R deployer:deployer /home/deployer

################################################################################
# Display Setup Summary
################################################################################
log "=========================================="
log "VPS Setup Completed Successfully!"
log "=========================================="
log ""
log "Summary:"
log "- Docker and Docker Compose installed"
log "- Firewall (UFW) configured"
log "- Fail2Ban enabled"
log "- SSH hardened"
log "- Deploy user created"
log "- Cron jobs scheduled"
log "- System optimized for 1GB RAM"
log ""
log "Next Steps:"
log "1. Add your SSH public key to /home/deployer/.ssh/authorized_keys"
log "2. Copy application files to /home/deployer/ecommerce-api/"
log "3. Configure environment variables"
log "4. Run: docker-compose up -d"
log ""
log "VPS is ready for deployment!"
