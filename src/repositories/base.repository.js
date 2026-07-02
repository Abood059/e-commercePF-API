class BaseRepository {
    constructor(model) {
        this.model = model;
    }

    async create(data) {
        return await this.model.create(data);
    }

    async findById(id) {
        return await this.model.findById(id).lean();
    }

    async findOne(criteria) {
        return await this.model.findOne(criteria).lean();
    }

    async find(criteria = {}, options = {}) {
        const { skip, limit, sort, select } = options;
        let query = this.model.find(criteria);

        if (select) {
            query = query.select(select);
        }

        if (sort) {
            query = query.sort(sort);
        }

        if (skip) {
            query = query.skip(skip);
        }

        if (limit) {
            query = query.limit(limit);
        }

        return await query.lean();
    }

    async updateById(id, data) {
        return await this.model.findByIdAndUpdate(id, data, { new: true }).lean();
    }

    async updateOne(criteria, data) {
        return await this.model.findOneAndUpdate(criteria, data, { new: true }).lean();
    }

    async deleteById(id) {
        return await this.model.findByIdAndDelete(id).lean();
    }

    async deleteOne(criteria) {
        return await this.model.findOneAndDelete(criteria).lean();
    }

    async count(criteria = {}) {
        return await this.model.countDocuments(criteria);
    }

    async exists(criteria) {
        return await this.model.exists(criteria);
    }
}

module.exports = BaseRepository;
