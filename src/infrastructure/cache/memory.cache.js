const NodeCache = require('node-cache');

class CacheService {
    constructor(ttlSeconds = 300) {
        this.cache = new NodeCache({ stdTTL: ttlSeconds, checkperiod: ttlSeconds * 0.2 });
    }

    get(key) {
        return this.cache.get(key);
    }

    set(key, value, ttl) {
        return this.cache.set(key, value, ttl);
    }

    del(key) {
        return this.cache.del(key);
    }

    flushAll() {
        return this.cache.flushAll();
    }

    getStats() {
        return this.cache.getStats();
    }
}

module.exports = new CacheService(parseInt(process.env.CACHE_TTL) || 300);
