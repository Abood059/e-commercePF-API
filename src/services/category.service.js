const AppError = require('../utils/AppError');
const categoryRepository = require('../repositories/category.repository');
const cacheService = require('../infrastructure/cache/memory.cache');

class CategoryService {
    async getAllCategories() {
        const cacheKey = 'all_categories';
        let categories = cacheService.get(cacheKey);

        if (categories) {
            return categories;
        }

        categories = await categoryRepository.find();
        cacheService.set(cacheKey, categories);

        return categories;
    }

    async getCategoryById(id) {
        const category = await categoryRepository.findById(id);

        if (!category) {
            throw new AppError('Category not found', 404);
        }

        return category;
    }

    async createCategory(data) {
        const existingCategory = await categoryRepository.findByName(data.name);

        if (existingCategory) {
            throw new AppError('Category with this name already exists', 400);
        }

        const category = await categoryRepository.create(data);

        cacheService.flushAll();

        return category;
    }

    async updateCategory(id, data) {
        const category = await categoryRepository.updateById(id, data);

        if (!category) {
            throw new AppError('Category not found', 404);
        }

        cacheService.flushAll();

        return category;
    }

    async deleteCategory(id) {
        const category = await categoryRepository.findById(id);

        if (!category) {
            throw new AppError('Category not found', 404);
        }

        await categoryRepository.deleteById(id);

        cacheService.flushAll();

        return { message: 'Category deleted successfully' };
    }

    async getCategoryWithProducts(id) {
        const category = await categoryRepository.findWithProducts(id);

        if (!category) {
            throw new AppError('Category not found', 404);
        }

        return category;
    }
}

module.exports = new CategoryService();
