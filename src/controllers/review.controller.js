const reviewService = require('../services/review.service');
const ApiResponse = require('../utils/apiResponse');

class ReviewController {
    async createReview(req, res, next) {
        try {
            const userId = req.user._id;
            const { productId } = req.params;
            const review = await reviewService.createReview(userId, productId, req.body);
            res.status(201).json(ApiResponse.success(review));
        } catch (error) {
            next(error);
        }
    }

    async getProductReviews(req, res, next) {
        try {
            const { productId } = req.params;
            const result = await reviewService.getProductReviews(productId);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async updateReview(req, res, next) {
        try {
            const { id } = req.params;
            const userId = req.user._id;
            const review = await reviewService.updateReview(id, userId, req.body);
            res.json(ApiResponse.success(review));
        } catch (error) {
            next(error);
        }
    }

    async deleteReview(req, res, next) {
        try {
            const { id } = req.params;
            const userId = req.user._id;
            const result = await reviewService.deleteReview(id, userId);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async getUserReviews(req, res, next) {
        try {
            const userId = req.user._id;
            const reviews = await reviewService.getUserReviews(userId);
            res.json(ApiResponse.success(reviews));
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new ReviewController();
