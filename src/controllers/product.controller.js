const productService = require('../services/product.service');
const ApiResponse = require('../utils/apiResponse');

class ProductController {
    async getAllProducts(req, res, next) {
        try {
            const products = await productService.getAllProducts();
            res.json(ApiResponse.success(products));
        } catch (error) {
            next(error);
        }
    }

    async getProductById(req, res, next) {
        try {
            const { id } = req.params;
            const product = await productService.getProductById(id);
            res.json(ApiResponse.success(product));
        } catch (error) {
            next(error);
        }
    }

    async getProductByName(req, res, next) {
        try {
            const { name } = req.params;
            const products = await productService.getProductByName(name);
            res.json(ApiResponse.success(products));
        } catch (error) {
            next(error);
        }
    }

    async createProduct(req, res, next) {
        try {
            const product = await productService.createProduct(req.body);
            res.status(201).json(ApiResponse.success(product));
        } catch (error) {
            next(error);
        }
    }

    async updateProduct(req, res, next) {
        try {
            const { id } = req.params;
            const product = await productService.updateProduct(id, req.body);
            res.json(ApiResponse.success(product));
        } catch (error) {
            next(error);
        }
    }

    async deleteProduct(req, res, next) {
        try {
            const { id } = req.params;
            const result = await productService.deleteProduct(id);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async getPaginatedProducts(req, res, next) {
        try {
            const { page, limit, category, brand, name, pricemin, pricemax, sortBy } = req.query;
            const filters = { category, brand, name, pricemin, pricemax };
            const pagination = { page: parseInt(page) || 1, limit: parseInt(limit) || 10 };
            const result = await productService.getPaginatedProducts(filters, pagination, sortBy);
            res.json(ApiResponse.paginated(result.products, result.pagination));
        } catch (error) {
            next(error);
        }
    }

    async getBrands(req, res, next) {
        try {
            const brands = await productService.getBrands();
            res.json(ApiResponse.success(brands));
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new ProductController();
