const AppError = require('../utils/AppError');
const reviewRepository = require('../repositories/review.repository');
const orderRepository = require('../repositories/order.repository');
const cacheService = require('../infrastructure/cache/memory.cache');

class ReviewService {
    async createReview(userId, productId, reviewData) {
        const existingReview = await reviewRepository.findByUserAndProduct(userId, productId);

        if (existingReview) {
            throw new AppError('You have already reviewed this product', 400);
        }

        const purchasedProducts = await orderRepository.getUserPurchasedProducts(userId);

        if (!purchasedProducts.includes(productId.toString())) {
            throw new AppError('You must purchase this product to review it', 400);
        }

        const review = await reviewRepository.create({
            user: userId,
            id_product: productId,
            ...reviewData,
        });

        await reviewRepository.updateProductRating(productId);

        cacheService.flushAll();

        return review;
    }

    async getProductReviews(productId) {
        const reviews = await reviewRepository.findByProductId(productId);
        const ratingData = await reviewRepository.getAverageRating(productId);

        return {
            reviews,
            averageRating: ratingData.averageRating,
            reviewCount: ratingData.count,
        };
    }

    async updateReview(reviewId, userId, reviewData) {
        const review = await reviewRepository.findById(reviewId);

        if (!review) {
            throw new AppError('Review not found', 404);
        }

        if (review.user.toString() !== userId.toString()) {
            throw new AppError('Access denied', 403);
        }

        const updatedReview = await reviewRepository.updateById(reviewId, reviewData);

        await reviewRepository.updateProductRating(review.id_product);

        cacheService.flushAll();

        return updatedReview;
    }

    async deleteReview(reviewId, userId) {
        const review = await reviewRepository.findById(reviewId);

        if (!review) {
            throw new AppError('Review not found', 404);
        }

        if (review.user.toString() !== userId.toString()) {
            throw new AppError('Access denied', 403);
        }

        const productId = review.id_product;

        await reviewRepository.deleteById(reviewId);

        await reviewRepository.updateProductRating(productId);

        cacheService.flushAll();

        return { message: 'Review deleted successfully' };
    }

    async getUserReviews(userId) {
        return await reviewRepository.findByUser(userId);
    }
}

module.exports = new ReviewService();
