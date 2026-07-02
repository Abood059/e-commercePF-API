const express = require('express');
const Joi = require('joi');
const router = express.Router();
const productController = require('../controllers/product.controller');
const { validate, validateQuery, validateParams } = require('../middlewares/validation.middleware');
const { productValidators, objectId } = require('../utils/validators');
const { authenticateJWT, authorizeRoles } = require('../middlewares/auth.middleware');
const { adminLimiter } = require('../middlewares/rateLimit.middleware');

router.get('/', productController.getAllProducts.bind(productController));
router.get('/paginated', validateQuery(productValidators.getPaginated), productController.getPaginatedProducts.bind(productController));
router.get('/brands', productController.getBrands.bind(productController));
router.get('/name/:name', productController.getProductByName.bind(productController));
router.get('/:id', validateParams(Joi.object({ id: objectId })), productController.getProductById.bind(productController));
router.post('/', adminLimiter, authenticateJWT, authorizeRoles('admin'), validate(productValidators.create), productController.createProduct.bind(productController));
router.put('/:id', validateParams(Joi.object({ id: objectId })), adminLimiter, authenticateJWT, authorizeRoles('admin'), validate(productValidators.update), productController.updateProduct.bind(productController));
router.delete('/:id', validateParams(Joi.object({ id: objectId })), adminLimiter, authenticateJWT, authorizeRoles('admin'), productController.deleteProduct.bind(productController));

module.exports = router;
