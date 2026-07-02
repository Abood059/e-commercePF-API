const AppError = require('../utils/AppError');
const ApiResponse = require('../utils/apiResponse');
const config = require('../config');

const errorHandler = (err, req, res, next) => {
    if (err instanceof AppError) {
        return res.status(err.statusCode).json(
            ApiResponse.error(err.message, err.statusCode)
        );
    }

    if (err.name === 'ValidationError') {
        const errors = Object.values(err.errors).map(e => e.message);
        return res.status(400).json(
            ApiResponse.error(errors.join(', '), 400, 'VALIDATION_ERROR')
        );
    }

    if (err.name === 'CastError') {
        return res.status(400).json(
            ApiResponse.error('Invalid ID format', 400, 'CAST_ERROR')
        );
    }

    if (err.code === 11000) {
        const field = Object.keys(err.keyValue)[0];
        return res.status(400).json(
            ApiResponse.error(`${field} already exists`, 400, 'DUPLICATE_ERROR')
        );
    }

    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json(
            ApiResponse.error('Invalid token', 401, 'JWT_ERROR')
        );
    }

    if (err.name === 'TokenExpiredError') {
        return res.status(401).json(
            ApiResponse.error('Token expired', 401, 'JWT_ERROR')
        );
    }

    console.error('ERROR:', err);

    const statusCode = err.statusCode || 500;
    const message = config.server.env === 'development' ? err.message : 'Internal server error';

    res.status(statusCode).json(
        ApiResponse.error(message, statusCode, 'INTERNAL_ERROR')
    );
};

const notFound = (req, res, next) => {
    next(new AppError(`Route ${req.originalUrl} not found`, 404));
};

module.exports = {
    errorHandler,
    notFound,
};
