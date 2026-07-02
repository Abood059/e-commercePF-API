const { Schema, model } = require('mongoose');

const orderItemSchema = new Schema({
    productId: {
        type: Schema.Types.ObjectId,
        ref: 'Product',
        required: true
    },
    quantity: {
        type: Number,
        required: true,
        min: 1
    },
    price: {
        type: Number,
        required: true
    },
    name: {
        type: String,
        required: true
    }
}, { _id: false });

const orderSchema = new Schema(
    {
        userId: {
            type: Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        products: [orderItemSchema],
        totalAmount: {
            type: Number,
            required: true,
            min: 0
        },
        status: {
            type: String,
            enum: ['pending', 'processing', 'shipped', 'delivered', 'cancelled'],
            default: 'pending'
        },
        paymentStatus: {
            type: String,
            enum: ['pending', 'completed', 'failed', 'refunded'],
            default: 'pending'
        },
        paymentIntentId: {
            type: String
        },
        shippingAddress: {
            street: String,
            city: String,
            country: String,
            postalCode: String
        }
    },
    { 
        timestamps: true, 
        versionKey: false 
    }
);

const Order = model('Order', orderSchema);

module.exports = Order;
