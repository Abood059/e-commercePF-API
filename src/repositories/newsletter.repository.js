const BaseRepository = require('./base.repository');
const Newsletter = require('../domain/newsletter.entity');

class NewsletterRepository extends BaseRepository {
    constructor() {
        super(Newsletter);
    }

    async findByEmail(email) {
        return await this.model.findOne({ email }).lean();
    }

    async findActive() {
        return await this.model.find({ isActive: true }).lean();
    }

    async toggleActive(email) {
        const subscription = await this.model.findOne({ email });
        if (!subscription) {
            return null;
        }
        return await this.model.findByIdAndUpdate(
            subscription._id,
            { isActive: !subscription.isActive },
            { new: true }
        ).lean();
    }
}

module.exports = new NewsletterRepository();
