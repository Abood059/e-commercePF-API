const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const productRoutes = require('./product.routes');
const orderRoutes = require('./order.routes');
const reviewRoutes = require('./review.routes');
const userRoutes = require('./user.routes');
const categoryRoutes = require('./category.routes');
const newsletterRoutes = require('./newsletter.routes');

router.use('/auth', authRoutes);
router.use('/products', productRoutes);
router.use('/orders', orderRoutes);
router.use('/reviews', reviewRoutes);
router.use('/users', userRoutes);
router.use('/categories', categoryRoutes);
router.use('/newsletter', newsletterRoutes);

module.exports = router;
