const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        this.transporter = null;
    }

    initialize() {
        this.transporter = nodemailer.createTransport({
            host: 'smtp.gmail.com',
            port: 465,
            secure: true,
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS,
            },
            tls: {
                rejectUnauthorized: true
            },
            disableFileAccess: true,
            disableUrlAccess: true
        });

        this.transporter.verify().then(() => {
            console.log('Email service ready');
        }).catch((error) => {
            console.error('Email service error:', error);
        });
    }

    async sendEmail(options) {
        if (!this.transporter) {
            this.initialize();
        }

        const defaultOptions = {
            from: `"Sports-Market" <${process.env.EMAIL_USER}>`,
        };

        try {
            const info = await this.transporter.sendMail({ ...defaultOptions, ...options });
            console.log('Email sent:', info.response);
            return info;
        } catch (error) {
            console.error('Email sending error:', error);
            throw error;
        }
    }

    async sendActivationEmail(email, token) {
        const activationUrl = `${process.env.CLIENT_URL}/api/auth/activate/${token}`;
        return this.sendEmail({
            to: email,
            subject: 'Account Activation Link',
            html: `<h2>Please click on given link to activate your account:</h2>
                   <p><a href="${activationUrl}">${activationUrl}</a></p>`
        });
    }

    async sendPasswordResetEmail(email, token) {
        const resetUrl = `${process.env.CLIENT_URL}/resetpassword/${token}`;
        return this.sendEmail({
            to: email,
            subject: 'Password Reset Link',
            html: `<h2>Please click on given link to reset your password:</h2>
                   <p><a href="${resetUrl}">${resetUrl}</a></p>`
        });
    }

    async sendNewsletter(email, title, body) {
        return this.sendEmail({
            to: email,
            subject: title,
            html: body
        });
    }

    async sendForceResetEmail(email, newPassword) {
        return this.sendEmail({
            to: email,
            subject: 'Force Reset Password',
            html: `<h2>Your Password has been changed by an admin.</h2>
                   <p>Your new password is ${newPassword}</p>`
        });
    }
}

module.exports = new EmailService();
