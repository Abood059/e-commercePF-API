const jwt = require('jsonwebtoken');
const AppError = require('../utils/AppError');
const config = require('../config');
const { logFailedAuth, logUnauthorizedAccess, logAdminOperation } = require('../utils/securityLogger');

const authenticateJWT = (req, res, next) => {
    const authHeader = req.headers.authorization;
    const ip = req.ip || req.connection.remoteAddress;

    if (!authHeader) {
        logFailedAuth('unknown', ip, 'No token provided');
        return next(new AppError('No token provided', 401));
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
        logFailedAuth('unknown', ip, 'No token provided');
        return next(new AppError('No token provided', 401));
    }

    jwt.verify(token, config.jwt.secret, { algorithms: ['HS256'] }, (err, user) => {
        if (err) {
            logFailedAuth(user?.email || 'unknown', ip, 'Invalid or expired token');
            return next(new AppError('Invalid or expired token', 401));
        }

        req.user = user;
        next();
    });
};

const authorizeRoles = (...roles) => {
    return (req, res, next) => {
        const ip = req.ip || req.connection.remoteAddress;
        if (!roles.includes(req.user.role)) {
            logUnauthorizedAccess(req.user._id, ip, req.originalUrl);
            return next(new AppError('You do not have permission to perform this action', 403));
        }
        
        if (roles.includes('admin') && req.user.role === 'admin') {
            logAdminOperation(req.user._id, ip, req.method + ' ' + req.originalUrl, {});
        }
        
        next();
    };
};

module.exports = {
    authenticateJWT,
    authorizeRoles,
};
