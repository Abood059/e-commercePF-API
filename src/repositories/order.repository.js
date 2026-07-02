const BaseRepository = require('./base.repository');
const Order = require('../domain/order.entity');

class OrderRepository extends BaseRepository {
    constructor() {
        super(Order);
    }

    async findByUserId(userId) {
        return await this.model.find({ userId }).lean();
    }

    async findByUserIdWithPagination(userId, page, limit) {
        const skip = (page - 1) * limit;
        const orders = await this.model
            .find({ userId })
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .lean();

        const total = await this.model.countDocuments({ userId });

        return {
            orders,
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        };
    }

    async updateStatus(orderId, status) {
        return await this.model.findByIdAndUpdate(
            orderId,
            { status },
            { new: true }
        ).lean();
    }

    async updatePaymentStatus(orderId, paymentStatus) {
        return await this.model.findByIdAndUpdate(
            orderId,
            { paymentStatus },
            { new: true }
        ).lean();
    }

    async findByPaymentIntentId(paymentIntentId) {
        return await this.model.findOne({ paymentIntentId }).lean();
    }

    async getUserPurchasedProducts(userId) {
        const orders = await this.model.find({ userId, status: { $in: ['delivered', 'shipped'] } }).lean();
        const productIds = orders.flatMap(order => 
            order.products.map(product => product.productId.toString())
        );
        return [...new Set(productIds)];
    }
}

module.exports = new OrderRepository();
