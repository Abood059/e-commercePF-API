require('dotenv').config();
const app = require('./app');
const database = require('./infrastructure/database/connection');
const emailService = require('./infrastructure/email/email.service');
const config = require('./config');

const PORT = config.server.port;

async function startServer() {
    try {
        await database.connect(config.database.url);
        emailService.initialize();

        app.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
            console.log(`Environment: ${config.server.env}`);
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

startServer();

process.on('unhandledRejection', (err) => {
    console.error('Unhandled Rejection:', err);
    process.exit(1);
});

process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
    process.exit(1);
});
