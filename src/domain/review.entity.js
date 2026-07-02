const { Schema, model } = require('mongoose');

const reviewSchema = new Schema(
    {
        user: {
            type: Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        id_product: {
            type: Schema.Types.ObjectId,
            ref: 'Product',
            required: true
        },
        rating: {
            type: Number,
            required: true,
            min: 1,
            max: 5
        },
        description: {
            type: String,
            required: true,
            trim: true,
            minlength: 1,
            maxlength: 1000
        }
    },
    { 
        timestamps: true, 
        versionKey: false 
    }
);

reviewSchema.index({ user: 1, id_product: 1 }, { unique: true });

const Review = model('Review', reviewSchema);

module.exports = Review;
