

import { connectDB } from "./db.js";





export const startServer = async () => {
    try {
      // Connect to MongoDB
      await connectDB()
    } catch (error) {
      console.error('Failed to start server:', error);
      process.exit(1);
    }
  };
  