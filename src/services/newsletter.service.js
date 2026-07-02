const AppError = require('../utils/AppError');
const newsletterRepository = require('../repositories/newsletter.repository');
const emailService = require('../infrastructure/email/email.service');

class NewsletterService {
    async getAllSubscribers() {
        return await newsletterRepository.findActive();
    }

    async subscribe(email) {
        const existingSubscription = await newsletterRepository.findByEmail(email);

        if (existingSubscription) {
            if (!existingSubscription.isActive) {
                await newsletterRepository.updateById(existingSubscription._id, { isActive: true });
                return { message: 'Newsletter subscription reactivated' };
            }
            throw new AppError('Email already subscribed to newsletter', 400);
        }

        await newsletterRepository.create({ email });

        return { message: 'Successfully subscribed to newsletter' };
    }

    async unsubscribe(email) {
        const subscription = await newsletterRepository.findByEmail(email);

        if (!subscription) {
            throw new AppError('Email not found in newsletter', 404);
        }

        await newsletterRepository.updateById(subscription._id, { isActive: false });

        return { message: 'Successfully unsubscribed from newsletter' };
    }

    async sendBulkNewsletter(title, body) {
        const subscribers = await newsletterRepository.findActive();

        for (const subscriber of subscribers) {
            await emailService.sendNewsletter(subscriber.email, title, body);
        }

        return { message: `Newsletter sent to ${subscribers.length} subscribers` };
    }
}

module.exports = new NewsletterService();
