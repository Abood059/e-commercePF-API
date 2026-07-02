class ApiResponse {
    static success(data, message = 'Success') {
        return {
            success: true,
            message,
            data,
        };
    }

    static error(message, statusCode = 500, code = null) {
        return {
            success: false,
            error: {
                message,
                statusCode,
                code,
            },
        };
    }

    static paginated(data, pagination, message = 'Success') {
        return {
            success: true,
            message,
            data,
            pagination: {
                page: pagination.page,
                limit: pagination.limit,
                total: pagination.total,
                totalPages: pagination.totalPages,
            },
        };
    }
}

module.exports = ApiResponse;
