const newsletterService = require('../services/newsletter.service');
const ApiResponse = require('../utils/apiResponse');

class NewsletterController {
    async getAllSubscribers(req, res, next) {
        try {
            const subscribers = await newsletterService.getAllSubscribers();
            res.json(ApiResponse.success(subscribers));
        } catch (error) {
            next(error);
        }
    }

    async subscribe(req, res, next) {
        try {
            const { email } = req.body;
            const result = await newsletterService.subscribe(email);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async unsubscribe(req, res, next) {
        try {
            const { email } = req.body;
            const result = await newsletterService.unsubscribe(email);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async sendBulkNewsletter(req, res, next) {
        try {
            const { title, body } = req.body;
            const result = await newsletterService.sendBulkNewsletter(title, body);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new NewsletterController();
