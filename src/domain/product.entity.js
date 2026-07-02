const { Schema, model } = require('mongoose');

const productSchema = new Schema(
    {
        sku: {
            type: String,
            unique: true,
            sparse: true
        },
        name: {
            type: String,
            required: true,
            trim: true
        },
        description: {
            type: String,
            trim: true
        },
        price: {
            type: Number,
            required: true,
            min: 0
        },
        quantity: {
            type: Number,
            required: true,
            min: 0,
            default: 0
        },
        isOnStock: {
            type: Boolean,
            default: true
        },
        img: [{
            type: String
        }],
        category: [{
            type: String,
            trim: true
        }],
        rating: {
            type: Number,
            default: 0,
            min: 0,
            max: 5
        },
        brand: {
            type: String,
            trim: true
        }
    },
    { 
        timestamps: true, 
        versionKey: false 
    }
);

const Product = model('Product', productSchema);

module.exports = Product;
