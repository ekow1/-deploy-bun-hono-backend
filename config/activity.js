import ActivityLog from "../model/activity.js";




const getUserLocation = async (ipAddress) => {
    try {
        if (!ipAddress || ipAddress === '127.0.0.1' || ipAddress === 'localhost') {
            return 'Local';
        }
        
        const response = await fetch(`https://ipinfo.io/${ipAddress}/json`);
        if (!response.ok) {
            return 'Unknown';
        }
        
        const data = await response.json();
        return data.city || data.region || 'Unknown';
    } catch (error) {
        console.error('Error getting location:', error);
        return 'Unknown';
    }
}

const trackUser = async (c) => {
    try {
        // Get IP address from various headers
        const ipAddress = c.req.header("x-forwarded-for") || 
                         c.req.header("x-real-ip") || 
                         c.req.header("cf-connecting-ip") ||
                         '127.0.0.1';
        
        // Get device info from user agent
        const userAgent = c.req.header("user-agent") || 'Unknown';
        let device = 'Unknown';
        
        if (userAgent.includes('PostmanRuntime')) {
            device = 'Postman';
        } else if (userAgent.includes('curl')) {
            device = 'cURL';
        } else if (userAgent.includes('Mozilla') || userAgent.includes('Chrome') || userAgent.includes('Safari') || userAgent.includes('Firefox') || userAgent.includes('Edge')) {
            // Browser detection with OS
            if (userAgent.includes('Android')) {
                device = 'Android Browser';
            } else if (userAgent.includes('iPhone') || userAgent.includes('iPad')) {
                device = 'iOS Browser';
            } else if (userAgent.includes('Mac OS X') || userAgent.includes('Macintosh')) {
                device = 'Mac Browser';
            } else if (userAgent.includes('Windows NT')) {
                device = 'Windows Browser';
            } else if (userAgent.includes('Linux')) {
                device = 'Linux Browser';
            } else {
                device = 'Browser';
            }
        } else if (userAgent.includes('Android')) {
            device = 'Android App';
        } else if (userAgent.includes('iPhone') || userAgent.includes('iPad')) {
            device = 'iOS App';
        } else if (userAgent.includes('Mac OS X') || userAgent.includes('Macintosh')) {
            device = 'Mac App';
        } else if (userAgent.includes('Windows NT')) {
            device = 'Windows App';
        } else if (userAgent.includes('Linux')) {
            device = 'Linux App';
        } else {
            device = userAgent.substring(0, 50); // Truncate long user agents
        }
        
        const location = await getUserLocation(ipAddress);
        
        return { ipAddress, device, location };
    } catch (error) {
        console.error('Error tracking user:', error);
        return { ipAddress: 'Unknown', device: 'Unknown', location: 'Unknown' };
    }
}


export const createActivity = async (c, userId, action, description) => {
    try {
        const { ipAddress, device, location } = await trackUser(c);
        
        const activityLog = await ActivityLog.create({ 
            userId, 
            action, 
            description, 
            ipAddress, 
            location, 
            device 
        });
        
        console.log(`Activity logged: ${action} - ${description} from ${device} at ${location}`);
        return activityLog;
    } catch (error) {
        console.error("Error creating activity log:", error);
        // Don't throw error to avoid breaking the main flow
        return null;
    }
}

export const getActivity = async (c) => {
    try {
        const activities = await ActivityLog.find({}).sort({ createdAt: -1 });
        return c.json(activities, 200);
    } catch (error) {
        console.error("Error getting activity:", error);
        throw error;
    }
}