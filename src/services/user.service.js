const AppError = require('../utils/AppError');
const userRepository = require('../repositories/user.repository');
const newsletterRepository = require('../repositories/newsletter.repository');
const emailService = require('../infrastructure/email/email.service');

class UserService {
    async getUserById(userId) {
        const user = await userRepository.findById(userId);

        if (!user) {
            throw new AppError('User not found', 404);
        }

        const { passwordHash, resetLink, ...userWithoutSensitive } = user;

        return userWithoutSensitive;
    }

    async updateUser(userId, updateData) {
        const user = await userRepository.updateById(userId, updateData);

        if (!user) {
            throw new AppError('User not found', 404);
        }

        const { passwordHash, resetLink, ...userWithoutSensitive } = user;

        return userWithoutSensitive;
    }

    async deleteUser(userId) {
        const user = await userRepository.findById(userId);

        if (!user) {
            throw new AppError('User not found', 404);
        }

        await userRepository.deleteById(userId);

        return { message: 'User deleted successfully' };
    }

    async subscribeToNewsletter(email) {
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

    async unsubscribeFromNewsletter(email) {
        const subscription = await newsletterRepository.findByEmail(email);

        if (!subscription) {
            throw new AppError('Email not found in newsletter', 404);
        }

        await newsletterRepository.updateById(subscription._id, { isActive: false });

        return { message: 'Successfully unsubscribed from newsletter' };
    }

    async sendNewsletter(title, body, email) {
        await emailService.sendNewsletter(email, title, body);

        return { message: 'Newsletter sent successfully' };
    }
}

module.exports = new UserService();
