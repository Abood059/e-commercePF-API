const express = require('express');
const cookieParser = require('cookie-parser');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const cors = require('cors');
const helmet = require('helmet');
const { generalLimiter } = require('./middlewares/rateLimit.middleware');

const routes = require('./routes');
const { errorHandler, notFound } = require('./middlewares/error.middleware');

const app = express();

app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "https:", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
        },
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    }
}));

app.use(cors({
    origin: process.env.CLIENT_URL || '*',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(bodyParser.json({ limit: '10kb' }));
app.use(bodyParser.urlencoded({ limit: '10kb', extended: false }));
app.use(cookieParser({
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict'
}));
app.use(morgan('dev'));
app.use(generalLimiter);

app.use('/api', routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
