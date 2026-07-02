const rateLimit = require('express-rate-limit');
const { logRateLimitTriggered } = require('../utils/securityLogger');

const createRateLimiter = (windowMs = 15 * 60 * 1000, max = 100, message = 'Too many requests') => {
    return rateLimit({
        windowMs,
        max,
        message: {
            success: false,
            error: {
                message,
                statusCode: 429,
                code: 'RATE_LIMIT_EXCEEDED',
            },
        },
        standardHeaders: true,
        legacyHeaders: false,
        handler: (req, res) => {
            const ip = req.ip || req.connection.remoteAddress;
            logRateLimitTriggered(ip, req.originalUrl);
            res.status(429).json({
                success: false,
                error: {
                    message,
                    statusCode: 429,
                    code: 'RATE_LIMIT_EXCEEDED',
                },
            });
        },
    });
};

const authLimiter = createRateLimiter(15 * 60 * 1000, 5, 'Too many authentication attempts, please try again later');
const generalLimiter = createRateLimiter(15 * 60 * 1000, 100, 'Too many requests from this IP, please try again later');
const orderLimiter = createRateLimiter(15 * 60 * 1000, 20, 'Too many order requests, please try again later');
const adminLimiter = createRateLimiter(15 * 60 * 1000, 30, 'Too many admin operations, please try again later');
const newsletterLimiter = createRateLimiter(60 * 60 * 1000, 5, 'Too many newsletter requests, please try again later');

module.exports = {
    createRateLimiter,
    authLimiter,
    generalLimiter,
    orderLimiter,
    adminLimiter,
    newsletterLimiter,
};
