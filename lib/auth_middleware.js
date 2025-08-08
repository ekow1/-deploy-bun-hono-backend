import { verifyToken, extractTokenFromCookie } from "../config/jwt.js";
import User from "../model/user-model.js";

export const authMiddleware = async (c, next) => {
    try {
        // Extract token from cookies
        const cookies = c.req.header("Cookie");
        const token = extractTokenFromCookie(parseCookies(cookies));
        
        if (!token) {
            return c.json({ message: "Unauthorized - No token provided" }, 401);
        }
        
        const decoded = verifyToken(token);
        const user = await User.findById(decoded.id);
        
        if (!user) {
            return c.json({ message: "Unauthorized - User not found" }, 401);
        }
        
        if (user.status === "inactive") {
            return c.json({ message: "Account is inactive" }, 401);
        }
        
        c.set("user", user);
        await next();
    } catch (error) {
        return c.json({ message: "Unauthorized - Invalid token" }, 401);
    }
};

// Helper function to parse cookies
function parseCookies(cookieHeader) {
    if (!cookieHeader) return {};
    
    const cookies = {};
    const pairs = cookieHeader.split(';');
    
    for (const pair of pairs) {
        const [key, value] = pair.trim().split('=');
        if (key && value) {
            cookies[key] = decodeURIComponent(value);
        }
    }
    
    return cookies;
}