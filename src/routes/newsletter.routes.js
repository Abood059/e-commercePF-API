const express = require('express');
const router = express.Router();
const newsletterController = require('../controllers/newsletter.controller');
const { authenticateJWT, authorizeRoles } = require('../middlewares/auth.middleware');
const { newsletterLimiter } = require('../middlewares/rateLimit.middleware');

router.get('/subscribers', authenticateJWT, authorizeRoles('admin'), newsletterController.getAllSubscribers.bind(newsletterController));
router.post('/subscribe', newsletterController.subscribe.bind(newsletterController));
router.post('/unsubscribe', newsletterController.unsubscribe.bind(newsletterController));
router.post('/send-bulk', newsletterLimiter, authenticateJWT, authorizeRoles('admin'), newsletterController.sendBulkNewsletter.bind(newsletterController));

module.exports = router;
