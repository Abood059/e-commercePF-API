const authService = require('../services/auth.service');
const ApiResponse = require('../utils/apiResponse');

class AuthController {
    async register(req, res, next) {
        try {
            const result = await authService.register(req.body);
            res.status(201).json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async activateAccount(req, res, next) {
        try {
            const { token } = req.params;
            const result = await authService.activateAccount(token);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async login(req, res, next) {
        try {
            const { email, password } = req.body;
            const result = await authService.login(email, password);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async googleLogin(req, res, next) {
        try {
            const { tokenId } = req.body;
            const result = await authService.googleLogin(tokenId);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async forgotPassword(req, res, next) {
        try {
            const { email } = req.body;
            const result = await authService.forgotPassword(email);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async resetPassword(req, res, next) {
        try {
            const { resetLink, newPass } = req.body;
            const result = await authService.resetPassword(resetLink, newPass);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async forceResetPassword(req, res, next) {
        try {
            const { _id } = req.body;
            const { role } = req.user;
            const result = await authService.forceResetPassword(_id, role);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new AuthController();
