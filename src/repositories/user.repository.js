const BaseRepository = require('./base.repository');
const User = require('../domain/user.entity');

class UserRepository extends BaseRepository {
    constructor() {
        super(User);
    }

    async findByEmail(email) {
        return await this.model.findOne({ email }).lean();
    }

    async findByResetLink(resetLink) {
        return await this.model.findOne({ resetLink }).lean();
    }

    async updateResetLink(userId, resetLink) {
        return await this.model.findByIdAndUpdate(userId, { resetLink }, { new: true }).lean();
    }

    async updatePassword(userId, passwordHash) {
        return await this.model.findByIdAndUpdate(
            userId,
            { passwordHash, resetLink: '' },
            { new: true }
        ).lean();
    }

    async updateRole(userId, role) {
        return await this.model.findByIdAndUpdate(userId, { role }, { new: true }).lean();
    }
}

module.exports = new UserRepository();
