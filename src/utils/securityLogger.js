const fs = require('fs');
const path = require('path');

const logFilePath = path.join(__dirname, '../../logs/security.log');

const ensureLogDirectory = () => {
    const logDir = path.dirname(logFilePath);
    if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
    }
};

const logSecurityEvent = (event, details = {}) => {
    ensureLogDirectory();
    
    const timestamp = new Date().toISOString();
    const logEntry = {
        timestamp,
        event,
        ...details
    };
    
    const logMessage = `[${timestamp}] ${event}: ${JSON.stringify(details)}\n`;
    
    fs.appendFile(logFilePath, logMessage, (err) => {
        if (err) {
            console.error('Failed to write security log:', err);
        }
    });
    
    console.log(`SECURITY: ${event}`, details);
};

const logFailedAuth = (email, ip, reason) => {
    logSecurityEvent('FAILED_AUTHENTICATION', { email, ip, reason });
};

const logUnauthorizedAccess = (userId, ip, endpoint) => {
    logSecurityEvent('UNAUTHORIZED_ACCESS', { userId, ip, endpoint });
};

const logRateLimitTriggered = (ip, endpoint) => {
    logSecurityEvent('RATE_LIMIT_TRIGGERED', { ip, endpoint });
};

const logAdminOperation = (userId, ip, operation, details) => {
    logSecurityEvent('ADMIN_OPERATION', { userId, ip, operation, details });
};

module.exports = {
    logSecurityEvent,
    logFailedAuth,
    logUnauthorizedAccess,
    logRateLimitTriggered,
    logAdminOperation,
};
