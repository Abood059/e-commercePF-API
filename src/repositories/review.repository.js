const BaseRepository = require('./base.repository');
const Review = require('../domain/review.entity');

class ReviewRepository extends BaseRepository {
    constructor() {
        super(Review);
    }

    async findByProductId(productId) {
        return await this.model.find({ id_product: productId }).lean();
    }

    async findByUserAndProduct(userId, productId) {
        return await this.model.findOne({ user: userId, id_product: productId }).lean();
    }

    async findByUser(userId) {
        return await this.model.find({ user: userId }).lean();
    }

    async getAverageRating(productId) {
        const result = await this.model.aggregate([
            { $match: { id_product: productId } },
            {
                $group: {
                    _id: '$id_product',
                    averageRating: { $avg: '$rating' },
                    count: { $sum: 1 }
                }
            }
        ]);

        if (result.length === 0) {
            return { averageRating: 0, count: 0 };
        }

        return {
            averageRating: result[0].averageRating,
            count: result[0].count
        };
    }

    async updateProductRating(productId) {
        const ratingData = await this.getAverageRating(productId);
        const Product = require('../domain/product.entity');
        await Product.findByIdAndUpdate(productId, { rating: ratingData.averageRating });
        return ratingData;
    }
}

module.exports = new ReviewRepository();
