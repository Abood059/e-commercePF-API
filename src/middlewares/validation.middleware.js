const Joi = require('joi');
const sanitizeHtml = require('sanitize-html');
const AppError = require('../utils/AppError');

const sanitizeObject = (obj) => {
    if (!obj || typeof obj !== 'object') return obj;
    
    for (const key in obj) {
        if (typeof obj[key] === 'string') {
            obj[key] = sanitizeHtml(obj[key], {
                allowedTags: [],
                allowedAttributes: {},
            });
        } else if (typeof obj[key] === 'object') {
            obj[key] = sanitizeObject(obj[key]);
        }
    }
    return obj;
};

const validate = (schema) => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true,
        });

        if (error) {
            const errors = error.details.map(detail => detail.message);
            return next(new AppError(errors.join(', '), 400));
        }

        req.body = sanitizeObject(value);
        next();
    };
};

const validateQuery = (schema) => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req.query, {
            abortEarly: false,
            stripUnknown: true,
        });

        if (error) {
            const errors = error.details.map(detail => detail.message);
            return next(new AppError(errors.join(', '), 400));
        }

        req.query = sanitizeObject(value);
        next();
    };
};

const validateParams = (schema) => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req.params, {
            abortEarly: false,
            stripUnknown: true,
        });

        if (error) {
            const errors = error.details.map(detail => detail.message);
            return next(new AppError(errors.join(', '), 400));
        }

        req.params = sanitizeObject(value);
        next();
    };
};

module.exports = {
    validate,
    validateQuery,
    validateParams,
};
