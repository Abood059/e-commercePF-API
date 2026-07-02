const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const AppError = require('../utils/AppError');
const config = require('../config');
const userRepository = require('../repositories/user.repository');
const emailService = require('../infrastructure/email/email.service');

const googleClient = new OAuth2Client(config.google.clientId);

class AuthService {
    async register(data) {
        const { name, email, password, role, newsLetter } = data;

        const existingUser = await userRepository.findByEmail(email);
        if (existingUser) {
            throw new AppError('User with this email already exists', 400);
        }

        const token = jwt.sign({ name, email, password, role, newsLetter }, config.jwt.secret);

        await emailService.sendActivationEmail(email, token);

        return { message: 'Email has been sent, kindly activate your account!' };
    }

    async activateAccount(token) {
        const decoded = jwt.verify(token, config.jwt.secret);
        const { name, email, password, role, newsLetter } = decoded;

        const existingUser = await userRepository.findByEmail(email);
        if (existingUser) {
            throw new AppError('User with this email already exists', 400);
        }

        const passwordHash = await bcrypt.hash(password, 10);

        const newUser = await userRepository.create({
            name,
            email,
            passwordHash,
            role: role || 'client',
            newsLetter: newsLetter || false,
        });

        if (newsLetter) {
            await emailService.sendNewsletter(email, 'Newsletter', '<h2>Newsletter</h2>');
        }

        return { message: 'Signup successful!' };
    }

    async login(email, password) {
        const user = await userRepository.findByEmail(email);

        if (!user) {
            throw new AppError('Invalid credentials', 401);
        }

        const passwordCheck = await bcrypt.compare(password, user.passwordHash);

        if (!passwordCheck) {
            throw new AppError('Invalid credentials', 401);
        }

        const token = jwt.sign(
            {
                _id: user._id,
                role: user.role,
                email: user.email,
            },
            config.jwt.secret
        );

        return { tokenId: token };
    }

    async googleLogin(tokenId) {
        const response = await googleClient.verifyIdToken({
            idToken: tokenId,
            audience: config.google.clientId,
        });

        const { email_verified, name, email } = response.payload;

        if (!email_verified) {
            throw new AppError('Email not verified', 400);
        }

        let user = await userRepository.findByEmail(email);

        if (user) {
            const token = jwt.sign(
                {
                    _id: user._id,
                    role: user.role,
                    email: user.email,
                },
                config.jwt.secret,
                { expiresIn: '7d' }
            );
            return { tokenId: token };
        }

        const password = email + config.jwt.secret;
        const passwordHash = await bcrypt.hash(password, 10);

        user = await userRepository.create({
            name,
            email,
            passwordHash,
        });

        const token = jwt.sign(
            {
                _id: user._id,
                role: user.role,
                email: user.email,
            },
            config.jwt.secret,
            { expiresIn: '7d' }
        );

        return { tokenId: token };
    }

    async forgotPassword(email) {
        const user = await userRepository.findByEmail(email);

        if (!user) {
            return { message: 'If the email exists, a reset link has been sent' };
        }

        const token = jwt.sign({ _id: user._id }, config.jwt.resetPasswordSecret);

        await userRepository.updateResetLink(user._id, token);

        await emailService.sendPasswordResetEmail(email, token);

        return { message: 'If the email exists, a reset link has been sent' };
    }

    async resetPassword(resetLink, newPass) {
        const decoded = jwt.verify(resetLink, config.jwt.resetPasswordSecret);

        const user = await userRepository.findByResetLink(resetLink);

        if (!user) {
            throw new AppError('User with this token does not exist', 400);
        }

        const passwordHash = await bcrypt.hash(newPass, 10);

        await userRepository.updatePassword(user._id, passwordHash);

        return { message: 'Your password has been changed' };
    }

    async forceResetPassword(userId, adminRole) {
        if (adminRole !== 'admin') {
            throw new AppError('Authentication error', 401);
        }

        const user = await userRepository.findById(userId);

        if (!user) {
            throw new AppError('User not found', 404);
        }

        const uniqid = require('uniqid');
        const newPassword = uniqid.process();
        const passwordHash = await bcrypt.hash(newPassword, 10);

        await userRepository.updatePassword(userId, passwordHash);

        await emailService.sendForceResetEmail(user.email, newPassword);

        return { message: 'Your password has been changed', data: newPassword, user };
    }
}

module.exports = new AuthService();
