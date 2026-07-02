const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { validate } = require('../middlewares/validation.middleware');
const { authValidators } = require('../utils/validators');
const { authLimiter } = require('../middlewares/rateLimit.middleware');

router.post('/register', authLimiter, validate(authValidators.register), authController.register.bind(authController));
router.post('/login', authLimiter, validate(authValidators.login), authController.login.bind(authController));
router.post('/google', authLimiter, validate(authValidators.googleLogin), authController.googleLogin.bind(authController));
router.post('/forgot-password', authLimiter, validate(authValidators.forgotPassword), authController.forgotPassword.bind(authController));
router.post('/reset-password', authLimiter, validate(authValidators.resetPassword), authController.resetPassword.bind(authController));
router.get('/activate/:token', authController.activateAccount.bind(authController));

module.exports = router;
