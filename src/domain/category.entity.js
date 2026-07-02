const { Schema, model } = require('mongoose');

const categorySchema = new Schema(
    {
        name: {
            type: String,
            required: true,
            unique: true,
            trim: true
        },
        description: {
            type: String,
            trim: true
        },
        products: [{
            type: Schema.Types.ObjectId,
            ref: 'Product'
        }]
    },
    { 
        timestamps: true, 
        versionKey: false 
    }
);

const Category = model('Category', categorySchema);

module.exports = Category;
