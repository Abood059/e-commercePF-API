const express = require('express');
const Joi = require('joi');
const router = express.Router();
const orderController = require('../controllers/order.controller');
const { validate, validateParams } = require('../middlewares/validation.middleware');
const { orderValidators, objectId } = require('../utils/validators');
const { authenticateJWT, authorizeRoles } = require('../middlewares/auth.middleware');
const { orderLimiter } = require('../middlewares/rateLimit.middleware');

router.post('/', orderLimiter, authenticateJWT, validate(orderValidators.create), orderController.createOrder.bind(orderController));
router.get('/', authenticateJWT, orderController.getUserOrders.bind(orderController));
router.get('/:id', validateParams(Joi.object({ id: objectId })), authenticateJWT, orderController.getOrderById.bind(orderController));
router.put('/:id/status', validateParams(Joi.object({ id: objectId })), authenticateJWT, authorizeRoles('admin'), validate(orderValidators.updateStatus), orderController.updateOrderStatus.bind(orderController));
router.post('/confirm-payment', orderLimiter, authenticateJWT, orderController.confirmPayment.bind(orderController));
router.delete('/:id', validateParams(Joi.object({ id: objectId })), authenticateJWT, orderController.cancelOrder.bind(orderController));

module.exports = router;
