const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const { validate } = require('../middlewares/validation.middleware');
const { userValidators } = require('../utils/validators');
const { authenticateJWT } = require('../middlewares/auth.middleware');

router.get('/me', authenticateJWT, userController.getCurrentUser.bind(userController));
router.put('/me', authenticateJWT, validate(userValidators.update), userController.updateUser.bind(userController));
router.delete('/me', authenticateJWT, userController.deleteUser.bind(userController));
router.post('/newsletter/subscribe', validate(userValidators.update), userController.subscribeNewsletter.bind(userController));
router.post('/newsletter/unsubscribe', validate(userValidators.update), userController.unsubscribeNewsletter.bind(userController));
router.post('/newsletter/send', authenticateJWT, validate(userValidators.newsletter), userController.sendNewsletter.bind(userController));

module.exports = router;
