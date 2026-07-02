const userService = require('../services/user.service');
const ApiResponse = require('../utils/apiResponse');

class UserController {
    async getCurrentUser(req, res, next) {
        try {
            const userId = req.user._id;
            const user = await userService.getUserById(userId);
            res.json(ApiResponse.success(user));
        } catch (error) {
            next(error);
        }
    }

    async updateUser(req, res, next) {
        try {
            const userId = req.user._id;
            const user = await userService.updateUser(userId, req.body);
            res.json(ApiResponse.success(user));
        } catch (error) {
            next(error);
        }
    }

    async deleteUser(req, res, next) {
        try {
            const userId = req.user._id;
            const result = await userService.deleteUser(userId);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async subscribeNewsletter(req, res, next) {
        try {
            const { email } = req.body;
            const result = await userService.subscribeToNewsletter(email);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async unsubscribeNewsletter(req, res, next) {
        try {
            const { email } = req.body;
            const result = await userService.unsubscribeFromNewsletter(email);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async sendNewsletter(req, res, next) {
        try {
            const { title, body, email } = req.body;
            const result = await userService.sendNewsletter(title, body, email);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new UserController();
