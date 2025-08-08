import User from "../model/user-model.js";
import sendEmail from "../config/mail.js";
import { generateToken, setAuthCookie, clearAuthCookie } from "../config/jwt.js";
import { createActivity, getActivity } from "../config/activity.js";

const sendVerificationEmail = async (c) => {
    try {
        const { email } = await c.req.json();
        
        const user = await User.findOne({ email });
        if (!user) {
            return c.json({ message: "User not found" }, 400);
        }
        
        const code = Math.floor(100000 + Math.random() * 900000);
        const verificationCodeExpiresAt = Date.now() + 10 * 60 * 1000;
        user.verificationCode = code;
        user.verificationCodeExpiresAt = new Date(verificationCodeExpiresAt);
        await user.save();
        
        const response = await sendEmail(email, "Verification Code", user.username, code);
        
        if (response.error) {
            return c.json({ message: "Failed to send verification email" }, 500);
        }
        return c.json({ message: "Verification email sent" }, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}


const createUser = async (c) => {
    try {
        const { name, username, email, password, role } = await c.req.json();
        
        if (!name || !username || !email || !password ) {
            return c.json({ message: "All fields are required" }, 400);
        }
        
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return c.json({ message: "User already exists" }, 400);
        }
        
        const existingUsername = await User.findOne({ username });
        if (existingUsername) {
            return c.json({ message: "Username already exists" }, 400);
        }
        
        const code = Math.floor(100000 + Math.random() * 900000);
        const verificationCodeExpiresAt = Date.now() + 10 * 60 * 1000;
        
        const user = await User.create({ 
            name, 
            username, 
            email, 
            password, 
            verificationCode: code,
            verificationCodeExpiresAt: new Date(verificationCodeExpiresAt)
        });

        // Send verification email after user creation
        try {
            const response = await sendEmail(email, "Verification Code", user.username, user.verificationCode);
            if (response.error) {
                console.error("Failed to send verification email:", response.error);
            }
            return c.json({ message: "Verification email sent" }, 200);
        } catch (emailError) {
            console.error("Email sending failed:", emailError);
        }

     
        
        return c.json(user, 201);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}


const verifyEmail = async (c) => {
    try {
        const { email, code } = await c.req.json();
        
        const user = await User.findOne({ email });
        if (!user) {
            return c.json({ message: "User not found" }, 400);
        }
        
        if (user.verificationCode !== code) {
            return c.json({ message: "Invalid verification code" }, 400);
        }
        
        if (user.verificationCodeExpiresAt < Date.now()) {
            return c.json({ message: "Verification code expired" }, 400);
        }

        user.status = "active";
        user.verificationCode = null;
        user.verificationCodeExpiresAt = null;
        await user.save();
        
        return c.json({ message: "Email verified successfully" }, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}

const resendVerificationEmail = async (c) => {
    try {
        const { email } = await c.req.json();
        const user = await User.findOne({ email });
        if (!user) {
            return c.json({ message: "User not found" }, 400);
        }
        const code = Math.floor(100000 + Math.random() * 900000);
        const verificationCodeExpiresAt = Date.now() + 10 * 60 * 1000;
        user.verificationCode = code;
        user.verificationCodeExpiresAt = new Date(verificationCodeExpiresAt);
        await user.save();
        const response = await sendEmail(email, "Verification Code", user.username, user.verificationCode);
        if (response.error) {
            return c.json({ message: "Failed to send verification email" }, 500);
        }
        return c.json({ message: "Verification email sent" }, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}

const login = async (c) => {
    try {
        const { email, password } = await c.req.json();
        
        const user = await User.findOne({ email });
        if (!user) {
            return c.json({ message: "User not found" }, 400);
        }
        
        if (user.status === "inactive") {
            return c.json({ message: "Please verify your email" }, 400);
        }
        
        const isPasswordCorrect = await user.comparePassword(password);
        if (!isPasswordCorrect) {
            return c.json({ message: "Invalid password" }, 400);
        }

        user.lastLogin = new Date();
        await user.save();
        const token = generateToken({ id: user._id });

        setAuthCookie(c, token);
        await createActivity(c, user._id, "login", "User logged in");

     
        
        return c.json({ message: "Logged in successfully" }, 200);

        
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}



const logout = async (c) => {
    try {
        // Clear the auth cookie
        clearAuthCookie(c);
        
        return c.json({ message: "Logged out successfully" }, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}

const getUsers = async (c) => {

    try {
        const currentUser = await User.findById(c.get("user").id);
        if (currentUser.role !== "admin") {
            return c.json({ message: "You are not authorized to access this resource" }, 403);
        }
        const users = await User.find();
        return c.json(users, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}



const requestPasswordReset = async (c) => {
    try {
        const { email } = await c.req.json();
        
        if (!email) {
            return c.json({ message: "Email is required" }, 400);
        }
        
        const user = await User.findOne({ email });
        if (!user) {
            return c.json({ message: "If an account with this email exists, a reset code has been sent" }, 200);
        }
        
        // Generate reset code
        const resetCode = Math.floor(100000 + Math.random() * 900000);
        const resetCodeExpiresAt = Date.now() + 15 * 60 * 1000; // 15 minutes
        
        user.resetCode = resetCode;
        user.resetCodeExpiresAt = new Date(resetCodeExpiresAt);
        await user.save();
        
        // Send reset email
        const response = await sendEmail(
            email, 
            "Password Reset Code", 
            user.username, 
            resetCode
        );
        
        if (response.error) {
            return c.json({ message: "Failed to send reset email" }, 500);
        }
        
        await createActivity(c, user._id, "password_reset_request", "Password reset requested");
        
        return c.json({ 
            message: "If an account with this email exists, a reset code has been sent" 
        }, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}

const verifyResetCode = async (c) => {
    try {
        const { email, resetCode } = await c.req.json();
        
        if (!email || !resetCode) {
            return c.json({ message: "Email and reset code are required" }, 400);
        }
        
        const user = await User.findOne({ email });
        if (!user) {
            return c.json({ message: "Invalid email or reset code" }, 400);
        }
        
        if (!user.resetCode || user.resetCode !== resetCode) {
            return c.json({ message: "Invalid reset code" }, 400);
        }
        
        if (user.resetCodeExpiresAt < Date.now()) {
            return c.json({ message: "Reset code has expired" }, 400);
        }
        
        return c.json({ 
            message: "Reset code verified successfully",
            email: user.email 
        }, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}

const resetPassword = async (c) => {
    try {
        const { email, resetCode, newPassword } = await c.req.json();
        
        if (!email || !resetCode || !newPassword) {
            return c.json({ message: "Email, reset code, and new password are required" }, 400);
        }
        
        if (newPassword.length < 8) {
            return c.json({ message: "Password must be at least 8 characters long" }, 400);
        }
        
        const user = await User.findOne({ email });
        if (!user) {
            return c.json({ message: "Invalid email or reset code" }, 400);
        }
        
        if (!user.resetCode || user.resetCode !== resetCode) {
            return c.json({ message: "Invalid reset code" }, 400);
        }
        
        if (user.resetCodeExpiresAt < Date.now()) {
            return c.json({ message: "Reset code has expired" }, 400);
        }
        
        // Update password
        user.password = newPassword;
        user.resetCode = null;
        user.resetCodeExpiresAt = null;
        await user.save();
        
        await createActivity(c, user._id, "password reset", "Password reset successfully");
        
        return c.json({ message: "Password reset successfully" }, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}

const getUserById = async (c) => {
    try {
        const { id } = c.req.param();
        const user = await User.findById(id);
        
        if (!user) {
            return c.json({ message: "User not found" }, 404);
        }
        
        return c.json(user, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}
const updateUser = async (c) => {
    try {
        const { id } = c.req.param();
        const { name, username, email} = await c.req.json();
        const user = await User.findByIdAndUpdate(id, { name, username, email }, { new: true });
        if (!user) {
            return c.json({ message: "User not found" }, 404);
        }
        return c.json(user, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}

const updateUserPassword = async (c) => {
    try {
        const { oldPassword, newPassword} = await c.req.json();
        const user = await User.findById(c.get("user").id);
        if (!user) {
            return c.json({ message: "User not found" }, 404);
        }
        const isPasswordCorrect = await user.comparePassword(oldPassword);
        if (!isPasswordCorrect) {
            return c.json({ message: "Invalid password" }, 400);
        }
        user.password = newPassword;
        await user.save();
        await createActivity(c, user._id, "password update", "Password updated successfully");
        return c.json({ message: "Password updated successfully" }, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}


const updateUserStatus = async (c) => {
    try {
        const { id } = c.req.param();
        const { status } = await c.req.json();
        
        const user = await User.findByIdAndUpdate(
            id, 
            { status }, 
            { new: true }
        );
        
        if (!user) {
            return c.json({ message: "User not found" }, 404);
        }
        
        return c.json(user, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}

const deleteUser = async (c) => {
    try {
        const { id } = c.req.param();
        if (currentUser.role !== "admin") {
            return c.json({ message: "You are not authorized to access this resource" }, 403);
        }
        
        const user = await User.findByIdAndDelete(id);
        if (!user) {
            return c.json({ message: "User not found" }, 404);
        }
        await createActivity(c, user._id, "delete user", `User deleted successfully by ${currentUser.name} (${currentUser.email})`);
        
        return c.json({ message: "User deleted successfully" }, 200);
    } catch (error) {
        return c.json({ message: error.message }, 500);
    }
}



export {
    createUser,
    sendVerificationEmail,
    verifyEmail,
    login,
    logout,
    getUsers,
    getUserById,
    updateUserStatus,
    deleteUser,
    resendVerificationEmail,
    requestPasswordReset,
    verifyResetCode,
    resetPassword,
    getActivity,
    updateUser,
    updateUserPassword
};









