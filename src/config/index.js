require('dotenv').config();

const config = {
  database: {
    url: process.env.MONGO_DB_URL,
  },
  server: {
    port: process.env.PORT || 3000,
    env: process.env.NODE_ENV || 'development',
  },
  jwt: {
    secret: process.env.SECRET_KEY,
    resetPasswordSecret: process.env.RESET_PASSWORD_KEY,
  },
  google: {
    clientId: process.env.AUTH_GOOGLE_CLIENT,
  },
  stripe: {
    secretKey: process.env.STRIPE_SECRET_KEY,
  },
  email: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
  client: {
    url: process.env.CLIENT_URL,
  },
  cache: {
    ttl: parseInt(process.env.CACHE_TTL) || 300,
  },
};

module.exports = config;
