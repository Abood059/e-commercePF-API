const { Schema, model } = require('mongoose');

const userSchema = new Schema(
    {
        name: {
            type: String,
            required: true,
            max: 64,
            trim: true
        },  
        email: {
            type: String,
            trim: true,
            required: true,
            unique: true,
            lowercase: true
        },
        passwordHash: {
            type: String,
            required: true
        } ,
        role: {
            type: String,
            enum: ['admin', 'client', 'moderator'],
            default: 'client'
        },
        resetLink: {
            type: String,
            default: ''
        },
        newsLetter: {
            type: Boolean,
            default: false
        }
    }, 
    { 
        timestamps: true, 
        versionKey: false
    }
);

const User = model('User', userSchema);

module.exports = User;
