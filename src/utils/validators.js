const Joi = require('joi');

// Common validators
const objectId = Joi.string().pattern(/^[0-9a-fA-F]{24}$/).required();

const authValidators = {
    register: Joi.object({
        name: Joi.string().min(2).max(64).required(),
        email: Joi.string().email().required(),
        password: Joi.string().min(6).required(),
        role: Joi.string().valid('admin', 'client', 'moderator').optional(),
        newsLetter: Joi.boolean().optional(),
    }),

    login: Joi.object({
        email: Joi.string().email().required(),
        password: Joi.string().required(),
    }),

    googleLogin: Joi.object({
        tokenId: Joi.string().required(),
    }),

    forgotPassword: Joi.object({
        email: Joi.string().email().required(),
    }),

    resetPassword: Joi.object({
        resetLink: Joi.string().required(),
        newPass: Joi.string().min(6).required(),
    }),

    forceResetPassword: Joi.object({
        _id: Joi.string().required(),
    }),
};

const productValidators = {
    create: Joi.object({
        sku: Joi.string().optional(),
        name: Joi.string().required(),
        description: Joi.string().optional(),
        price: Joi.number().min(0).required(),
        quantity: Joi.number().min(0).required(),
        isOnStock: Joi.boolean().optional(),
        img: Joi.array().items(Joi.string()).optional(),
        category: Joi.array().items(Joi.string()).optional(),
        brand: Joi.string().optional(),
    }),

    update: Joi.object({
        sku: Joi.string().optional(),
        name: Joi.string().optional(),
        description: Joi.string().optional(),
        price: Joi.number().min(0).optional(),
        quantity: Joi.number().min(0).optional(),
        isOnStock: Joi.boolean().optional(),
        img: Joi.array().items(Joi.string()).optional(),
        category: Joi.array().items(Joi.string()).optional(),
        brand: Joi.string().optional(),
    }),

    getPaginated: Joi.object({
        page: Joi.number().min(1).default(1),
        limit: Joi.number().min(1).max(100).default(10),
        category: Joi.string().optional(),
        brand: Joi.string().optional(),
        name: Joi.string().optional(),
        pricemin: Joi.number().min(0).optional(),
        pricemax: Joi.number().min(0).optional(),
        sortBy: Joi.string().valid('price_asc', 'price_desc', 'name_asc', 'name_desc').optional(),
    }),
};

const reviewValidators = {
    create: Joi.object({
        rating: Joi.number().min(1).max(5).required(),
        description: Joi.string().min(1).max(1000).required(),
    }),

    update: Joi.object({
        rating: Joi.number().min(1).max(5).optional(),
        description: Joi.string().min(1).max(1000).optional(),
    }),
};

const orderValidators = {
    create: Joi.object({
        products: Joi.array().items(
            Joi.object({
                productId: Joi.string().required(),
                quantity: Joi.number().min(1).required(),
            })
        ).required(),
        shippingAddress: Joi.object({
            street: Joi.string().required(),
            city: Joi.string().required(),
            country: Joi.string().required(),
            postalCode: Joi.string().required(),
        }).required(),
    }),

    updateStatus: Joi.object({
        status: Joi.string().valid('pending', 'processing', 'shipped', 'delivered', 'cancelled').required(),
    }),
};

const categoryValidators = {
    create: Joi.object({
        name: Joi.string().required(),
        description: Joi.string().optional(),
    }),

    update: Joi.object({
        name: Joi.string().optional(),
        description: Joi.string().optional(),
    }),
};

const userValidators = {
    update: Joi.object({
        name: Joi.string().min(2).max(64).optional(),
        newsLetter: Joi.boolean().optional(),
    }),

    newsletter: Joi.object({
        title: Joi.string().required(),
        body: Joi.string().required(),
        email: Joi.string().email().required(),
    }),
};

module.exports = {
    authValidators,
    productValidators,
    reviewValidators,
    orderValidators,
    categoryValidators,
    userValidators,
    objectId,
};
