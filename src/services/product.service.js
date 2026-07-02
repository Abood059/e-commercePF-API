const AppError = require('../utils/AppError');
const productRepository = require('../repositories/product.repository');
const reviewRepository = require('../repositories/review.repository');
const categoryRepository = require('../repositories/category.repository');
const cacheService = require('../infrastructure/cache/memory.cache');

class ProductService {
    async getAllProducts() {
        const cacheKey = 'all_products';
        let products = cacheService.get(cacheKey);

        if (products) {
            return products;
        }

        products = await productRepository.find();
        cacheService.set(cacheKey, products);

        return products;
    }

    async getProductById(id) {
        const cacheKey = `product_${id}`;
        let product = cacheService.get(cacheKey);

        if (product) {
            return product;
        }

        product = await productRepository.findById(id);

        if (!product) {
            throw new AppError('Product not found', 404);
        }

        const reviews = await reviewRepository.findByProductId(id);
        const ratingData = await reviewRepository.getAverageRating(id);

        product = {
            ...product,
            rating: ratingData.averageRating,
            reviewCount: ratingData.count,
            reviews,
        };

        cacheService.set(cacheKey, product);

        return product;
    }

    async getProductByName(name) {
        const products = await productRepository.find({ name: { $regex: name, $options: 'i' } });

        if (!products || products.length === 0) {
            throw new AppError('No products found', 404);
        }

        return products;
    }

    async createProduct(data) {
        const product = await productRepository.create(data);

        if (data.category && data.category.length > 0) {
            for (const categoryName of data.category) {
                const category = await categoryRepository.findByName(categoryName);
                if (category) {
                    await categoryRepository.addProduct(category._id, product._id);
                }
            }
        }

        cacheService.flushAll();

        return product;
    }

    async updateProduct(id, data) {
        const product = await productRepository.updateById(id, data);

        if (!product) {
            throw new AppError('Product not found', 404);
        }

        cacheService.flushAll();

        return product;
    }

    async deleteProduct(id) {
        const product = await productRepository.findById(id);

        if (!product) {
            throw new AppError('Product not found', 404);
        }

        if (product.category && product.category.length > 0) {
            for (const categoryName of product.category) {
                const category = await categoryRepository.findByName(categoryName);
                if (category) {
                    await categoryRepository.removeProduct(category._id, id);
                }
            }
        }

        await productRepository.deleteById(id);

        cacheService.flushAll();

        return { message: 'Product deleted successfully' };
    }

    async getPaginatedProducts(filters, pagination, sort) {
        const cacheKey = `products_${JSON.stringify(filters)}_${JSON.stringify(pagination)}_${sort}`;
        let result = cacheService.get(cacheKey);

        if (result) {
            return result;
        }

        result = await productRepository.findWithFilters(filters, pagination, sort);

        cacheService.set(cacheKey, result);

        return result;
    }

    async getBrands() {
        const cacheKey = 'brands';
        let brands = cacheService.get(cacheKey);

        if (brands) {
            return brands;
        }

        brands = await productRepository.getBrands();
        cacheService.set(cacheKey, brands);

        return brands;
    }
}

module.exports = new ProductService();
