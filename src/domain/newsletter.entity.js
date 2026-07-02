const { Schema, model } = require('mongoose');

const newsletterSchema = new Schema(
    {
        email: {
            type: String,
            required: true,
            unique: true,
            trim: true,
            lowercase: true
        },
        isActive: {
            type: Boolean,
            default: true
        }
    },
    { 
        timestamps: true, 
        versionKey: false 
    }
);

const Newsletter = model('Newsletter', newsletterSchema);

module.exports = Newsletter;
