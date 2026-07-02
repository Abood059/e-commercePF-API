const BaseRepository = require('./base.repository');
const Product = require('../domain/product.entity');

class ProductRepository extends BaseRepository {
    constructor() {
        super(Product);
    }

    async findWithFilters(filters, pagination, sort) {
        const { category, brand, name, pricemin, pricemax } = filters;
        const { page, limit } = pagination;

        const matchCriteria = { quantity: { $gte: 1 } };

        if (category) {
            matchCriteria.category = category;
        }

        if (brand) {
            matchCriteria.brand = brand;
        }

        if (name) {
            matchCriteria.name = { $regex: name, $options: 'i' };
        }

        if (pricemin !== undefined || pricemax !== undefined) {
            matchCriteria.price = {};
            if (pricemin !== undefined) {
                matchCriteria.price.$gte = pricemin;
            }
            if (pricemax !== undefined) {
                matchCriteria.price.$lte = pricemax;
            }
        }

        let sortStage = {};
        if (sort) {
            switch (sort) {
                case 'price_asc':
                    sortStage = { price: 1 };
                    break;
                case 'price_desc':
                    sortStage = { price: -1 };
                    break;
                case 'name_asc':
                    sortStage = { name: 1 };
                    break;
                case 'name_desc':
                    sortStage = { name: -1 };
                    break;
                default:
                    sortStage = { createdAt: -1 };
            }
        } else {
            sortStage = { createdAt: -1 };
        }

        const skip = (page - 1) * limit;

        const pipeline = [
            { $match: matchCriteria },
            { $sort: sortStage },
            { $skip: skip },
            { $limit: limit },
        ];

        const products = await this.model.aggregate(pipeline);

        const countPipeline = [{ $match: matchCriteria }, { $count: 'total' }];
        const countResult = await this.model.aggregate(countPipeline);
        const total = countResult.length > 0 ? countResult[0].total : 0;

        return {
            products,
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        };
    }

    async getBrands() {
        const brands = await this.model.distinct('brand');
        return brands.filter(brand => brand);
    }

    async findBySku(sku) {
        return await this.model.findOne({ sku }).lean();
    }

    async updateCategory(productId, categoryId, action = 'add') {
        const update = action === 'add' 
            ? { $push: { category: categoryId } }
            : { $pull: { category: categoryId } };
        
        return await this.model.findByIdAndUpdate(productId, update, { new: true }).lean();
    }

    async decreaseQuantity(productId, quantity) {
        return await this.model.findByIdAndUpdate(
            productId,
            { $inc: { quantity: -quantity } },
            { new: true }
        ).lean();
    }

    async increaseQuantity(productId, quantity) {
        return await this.model.findByIdAndUpdate(
            productId,
            { $inc: { quantity: quantity } },
            { new: true }
        ).lean();
    }
}

module.exports = new ProductRepository();
