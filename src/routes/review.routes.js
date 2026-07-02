const express = require('express');
const Joi = require('joi');
const router = express.Router();
const reviewController = require('../controllers/review.controller');
const { validate, validateParams } = require('../middlewares/validation.middleware');
const { reviewValidators, objectId } = require('../utils/validators');
const { authenticateJWT } = require('../middlewares/auth.middleware');

router.get('/product/:productId', validateParams(Joi.object({ productId: objectId })), reviewController.getProductReviews.bind(reviewController));
router.get('/user', authenticateJWT, reviewController.getUserReviews.bind(reviewController));
router.post('/product/:productId', validateParams(Joi.object({ productId: objectId })), authenticateJWT, validate(reviewValidators.create), reviewController.createReview.bind(reviewController));
router.put('/:id', validateParams(Joi.object({ id: objectId })), authenticateJWT, validate(reviewValidators.update), reviewController.updateReview.bind(reviewController));
router.delete('/:id', validateParams(Joi.object({ id: objectId })), authenticateJWT, reviewController.deleteReview.bind(reviewController));

module.exports = router;
