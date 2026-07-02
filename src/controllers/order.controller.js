const orderService = require('../services/order.service');
const ApiResponse = require('../utils/apiResponse');

class OrderController {
    async createOrder(req, res, next) {
        try {
            const userId = req.user._id;
            const order = await orderService.createOrder(userId, req.body);
            res.status(201).json(ApiResponse.success(order));
        } catch (error) {
            next(error);
        }
    }

    async getUserOrders(req, res, next) {
        try {
            const userId = req.user._id;
            const { page = 1, limit = 10 } = req.query;
            const result = await orderService.getUserOrders(userId, parseInt(page), parseInt(limit));
            res.json(ApiResponse.paginated(result.orders, result.pagination));
        } catch (error) {
            next(error);
        }
    }

    async getOrderById(req, res, next) {
        try {
            const { id } = req.params;
            const userId = req.user._id;
            const userRole = req.user.role;
            const order = await orderService.getOrderById(id, userId, userRole);
            res.json(ApiResponse.success(order));
        } catch (error) {
            next(error);
        }
    }

    async updateOrderStatus(req, res, next) {
        try {
            const { id } = req.params;
            const { status } = req.body;
            const order = await orderService.updateOrderStatus(id, status);
            res.json(ApiResponse.success(order));
        } catch (error) {
            next(error);
        }
    }

    async confirmPayment(req, res, next) {
        try {
            const { paymentIntentId } = req.body;
            const result = await orderService.confirmPayment(paymentIntentId);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async cancelOrder(req, res, next) {
        try {
            const { id } = req.params;
            const userId = req.user._id;
            const result = await orderService.cancelOrder(id, userId);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new OrderController();
