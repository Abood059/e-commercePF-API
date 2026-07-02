const express = require('express');
const Joi = require('joi');
const router = express.Router();
const categoryController = require('../controllers/category.controller');
const { validate, validateParams } = require('../middlewares/validation.middleware');
const { categoryValidators, objectId } = require('../utils/validators');
const { authenticateJWT, authorizeRoles } = require('../middlewares/auth.middleware');
const { adminLimiter } = require('../middlewares/rateLimit.middleware');

router.get('/', categoryController.getAllCategories.bind(categoryController));
router.get('/:id', validateParams(Joi.object({ id: objectId })), categoryController.getCategoryById.bind(categoryController));
router.get('/:id/products', validateParams(Joi.object({ id: objectId })), categoryController.getCategoryWithProducts.bind(categoryController));
router.post('/', adminLimiter, authenticateJWT, authorizeRoles('admin'), validate(categoryValidators.create), categoryController.createCategory.bind(categoryController));
router.put('/:id', validateParams(Joi.object({ id: objectId })), adminLimiter, authenticateJWT, authorizeRoles('admin'), validate(categoryValidators.update), categoryController.updateCategory.bind(categoryController));
router.delete('/:id', validateParams(Joi.object({ id: objectId })), adminLimiter, authenticateJWT, authorizeRoles('admin'), categoryController.deleteCategory.bind(categoryController));

module.exports = router;
