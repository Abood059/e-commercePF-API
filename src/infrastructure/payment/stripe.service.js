const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

class StripeService {
    async createPaymentIntent(amount, currency = 'usd') {
        try {
            const paymentIntent = await stripe.paymentIntents.create({
                amount: Math.round(amount * 100), // Convert to cents
                currency,
            });
            return paymentIntent;
        } catch (error) {
            console.error('Stripe payment intent error:', error);
            throw error;
        }
    }

    async retrievePaymentIntent(paymentIntentId) {
        try {
            const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
            return paymentIntent;
        } catch (error) {
            console.error('Stripe retrieve error:', error);
            throw error;
        }
    }

    async confirmPaymentIntent(paymentIntentId) {
        try {
            const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId);
            return paymentIntent;
        } catch (error) {
            console.error('Stripe confirm error:', error);
            throw error;
        }
    }

    async cancelPaymentIntent(paymentIntentId) {
        try {
            const paymentIntent = await stripe.paymentIntents.cancel(paymentIntentId);
            return paymentIntent;
        } catch (error) {
            console.error('Stripe cancel error:', error);
            throw error;
        }
    }
}

module.exports = new StripeService();
