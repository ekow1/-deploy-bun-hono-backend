import { Hono } from "hono";
import { createUser, sendVerificationEmail, verifyEmail, login, logout, getUsers, getUserById, updateUserStatus, deleteUser, resendVerificationEmail, requestPasswordReset, verifyResetCode, resetPassword, getActivity, updateUser, updateUserPassword } from "../controller/user.js";
import { authMiddleware } from "../lib/auth_middleware.js";

const userRoutes = new Hono();



userRoutes.post("/register", createUser);
userRoutes.post("/send-verification", sendVerificationEmail);
userRoutes.post("/verify", verifyEmail);
userRoutes.post("/login", login);
userRoutes.post("/logout", logout);
userRoutes.post("/request-password-reset", requestPasswordReset);
userRoutes.post("/verify-reset-code", verifyResetCode);
userRoutes.post("/reset-password", resetPassword);
userRoutes.get("/all", authMiddleware, getUsers);
userRoutes.get("/activity", authMiddleware, getActivity);
userRoutes.get("/:id",authMiddleware, getUserById);
userRoutes.patch("/:id/status",authMiddleware,   updateUserStatus);
userRoutes.put("/update-user/:id",authMiddleware, updateUser);
userRoutes.patch("/update-password/:id",authMiddleware, updateUserPassword);
userRoutes.delete("/:id",authMiddleware, deleteUser);
userRoutes.post("/resend-verification", resendVerificationEmail);


export default userRoutes;
