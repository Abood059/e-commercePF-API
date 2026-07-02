const categoryService = require('../services/category.service');
const ApiResponse = require('../utils/apiResponse');

class CategoryController {
    async getAllCategories(req, res, next) {
        try {
            const categories = await categoryService.getAllCategories();
            res.json(ApiResponse.success(categories));
        } catch (error) {
            next(error);
        }
    }

    async getCategoryById(req, res, next) {
        try {
            const { id } = req.params;
            const category = await categoryService.getCategoryById(id);
            res.json(ApiResponse.success(category));
        } catch (error) {
            next(error);
        }
    }

    async createCategory(req, res, next) {
        try {
            const category = await categoryService.createCategory(req.body);
            res.status(201).json(ApiResponse.success(category));
        } catch (error) {
            next(error);
        }
    }

    async updateCategory(req, res, next) {
        try {
            const { id } = req.params;
            const category = await categoryService.updateCategory(id, req.body);
            res.json(ApiResponse.success(category));
        } catch (error) {
            next(error);
        }
    }

    async deleteCategory(req, res, next) {
        try {
            const { id } = req.params;
            const result = await categoryService.deleteCategory(id);
            res.json(ApiResponse.success(result));
        } catch (error) {
            next(error);
        }
    }

    async getCategoryWithProducts(req, res, next) {
        try {
            const { id } = req.params;
            const category = await categoryService.getCategoryWithProducts(id);
            res.json(ApiResponse.success(category));
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new CategoryController();
