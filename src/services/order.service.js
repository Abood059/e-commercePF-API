const AppError = require('../utils/AppError');
const orderRepository = require('../repositories/order.repository');
const productRepository = require('../repositories/product.repository');
const stripeService = require('../infrastructure/payment/stripe.service');
const emailService = require('../infrastructure/email/email.service');
const config = require('../config');

class OrderService {
    async createOrder(userId, orderData) {
        const { products, shippingAddress } = orderData;

        let totalAmount = 0;
        const orderProducts = [];

        for (const item of products) {
            const product = await productRepository.findById(item.productId);

            if (!product) {
                throw new AppError(`Product with id ${item.productId} not found`, 404);
            }

            if (product.quantity < item.quantity) {
                throw new AppError(`Insufficient stock for product ${product.name}`, 400);
            }

            totalAmount += product.price * item.quantity;

            orderProducts.push({
                productId: product._id,
                quantity: item.quantity,
                price: product.price,
                name: product.name,
            });

            await productRepository.decreaseQuantity(product._id, item.quantity);
        }

        const paymentIntent = await stripeService.createPaymentIntent(totalAmount);

        const order = await orderRepository.create({
            userId,
            products: orderProducts,
            totalAmount,
            shippingAddress,
            paymentIntentId: paymentIntent.id,
        });

        await emailService.sendEmail({
            to: userId,
            subject: 'Order Confirmation',
            html: `<h2>Your order has been created successfully</h2><p>Order ID: ${order._id}</p>`,
        });

        return order;
    }

    async getUserOrders(userId, page = 1, limit = 10) {
        return await orderRepository.findByUserIdWithPagination(userId, page, limit);
    }

    async getOrderById(orderId, userId, userRole) {
        const order = await orderRepository.findById(orderId);

        if (!order) {
            throw new AppError('Order not found', 404);
        }

        if (order.userId.toString() !== userId.toString() && userRole !== 'admin') {
            throw new AppError('Access denied', 403);
        }

        return order;
    }

    async updateOrderStatus(orderId, status) {
        const order = await orderRepository.updateStatus(orderId, status);

        if (!order) {
            throw new AppError('Order not found', 404);
        }

        return order;
    }

    async confirmPayment(paymentIntentId) {
        const paymentIntent = await stripeService.retrievePaymentIntent(paymentIntentId);

        if (paymentIntent.status === 'succeeded') {
            const order = await orderRepository.findByPaymentIntentId(paymentIntentId);

            if (order) {
                await orderRepository.updatePaymentStatus(order._id, 'completed');
            }

            return { success: true, order };
        }

        return { success: false };
    }

    async cancelOrder(orderId, userId) {
        const order = await orderRepository.findById(orderId);

        if (!order) {
            throw new AppError('Order not found', 404);
        }

        if (order.userId.toString() !== userId.toString()) {
            throw new AppError('Access denied', 403);
        }

        if (order.status !== 'pending') {
            throw new AppError('Cannot cancel order that is not pending', 400);
        }

        for (const item of order.products) {
            await productRepository.increaseQuantity(item.productId, item.quantity);
        }

        await orderRepository.updateStatus(orderId, 'cancelled');

        return { message: 'Order cancelled successfully' };
    }
}

module.exports = new OrderService();
