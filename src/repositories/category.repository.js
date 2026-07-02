const BaseRepository = require('./base.repository');
const Category = require('../domain/category.entity');

class CategoryRepository extends BaseRepository {
    constructor() {
        super(Category);
    }

    async findByName(name) {
        return await this.model.findOne({ name }).lean();
    }

    async addProduct(categoryId, productId) {
        return await this.model.findByIdAndUpdate(
            categoryId,
            { $push: { products: productId } },
            { new: true }
        ).lean();
    }

    async removeProduct(categoryId, productId) {
        return await this.model.findByIdAndUpdate(
            categoryId,
            { $pull: { products: productId } },
            { new: true }
        ).lean();
    }

    async findWithProducts(categoryId) {
        return await this.model.findById(categoryId).populate('products').lean();
    }
}

module.exports = new CategoryRepository();
