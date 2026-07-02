const mongoose = require('mongoose');

class Database {
    constructor() {
        if (Database.instance) {
            return Database.instance;
        }
        this.connection = null;
        Database.instance = this;
    }

    async connect(url) {
        if (this.connection) {
            return this.connection;
        }

        try {
            this.connection = await mongoose.connect(url, {
                useNewUrlParser: true,
                useUnifiedTopology: true,
            });
            console.log('Database connected successfully');
            return this.connection;
        } catch (error) {
            console.error('Database connection error:', error);
            throw error;
        }
    }

    async disconnect() {
        if (this.connection) {
            await mongoose.disconnect();
            this.connection = null;
            console.log('Database disconnected');
        }
    }

    getConnection() {
        return this.connection;
    }
}

module.exports = new Database();
