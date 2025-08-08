
// Activity Log Model

import mongoose, { Schema, model } from 'mongoose';

const activityLogSchema = new Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  action: { type: String,  required: true },
  description: { type: String },
  ipAddress: { type: String },
  location: { type: String },  // Country / City
  device: { type: String },    // Browser, OS
  createdAt: { type: Date, default: Date.now },
});

const ActivityLog = model('ActivityLog', activityLogSchema);
export default ActivityLog;
