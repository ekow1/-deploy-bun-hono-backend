import mongoose from "mongoose";
import { Schema, model } from "mongoose";



    const userSchema = new Schema({
        name: {
            type: String,
            required: true,
            trim: true,
        },
        username: {
            type: String,
            required: true,
            trim: true,
            unique: true,
            minlength: [3, "Username must be at least 3 characters long"],
            maxlength: [10, "Username must be at most 20 characters long"],
        },
        email: {
            type: String,
            required: true,
            trim: true,
            unique: true,
            lowercase: true,
            match: [/^\S+@\S+\.\S+$/, "Invalid email address"],
        },
        verificationCode: {
            type: String,
            trim: true,
        },
        verificationCodeExpiresAt: {
            type: Date,
        },
        resetCode: {
            type: String,
            trim: true,
        },
        resetCodeExpiresAt: {
            type: Date,
        },
        password: {
            type: String,
            required: true,
            trim: true,
            minlength: [8, "Password must be at least 8 characters long"],
           
        },
        role: {
            type: String,
            enum: ["admin", "user"],
            default: "user",
        },
        status: {   
            type: String,
            enum: ["active", "inactive"],
            default: "inactive",
        },
        lastLogin: {
            type: Date,
            default: Date.now,
        },
    }, {
        timestamps: true,
        toJSON: {
            transform: function(doc, ret) {
                delete ret.password;
                delete ret.createdAt;
                delete ret.updatedAt;
                return ret;
            },
        },
    });

    userSchema.pre("save", async function(next) {
        if (!this.isModified("password")) return next();
       try {
        this.password = await Bun.password.hash(this.password);
        next();
       } catch (error) {
        next(error);
       }
    }); 

    userSchema.methods.comparePassword = async function(password) {
        return await Bun.password.verify(password, this.password);
    };  

    const User = model("User", userSchema);
    export default User;







