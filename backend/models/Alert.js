// models/Alert.js - COMPLETE FILE
const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema({
  alertId: {
    type: String,
    required: true,
    unique: true
  },
  userId: {
    type: String,
    required: true
  },
  userName: {
    type: String,
    required: true
  },
  userPhone: {
    type: String,
    required: true
  },
  location: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    address: String,
    campus: String
  },
  description: {
    type: String,
    required: true
  },
  evidenceImages: [String],
  alertType: {
    type: String,
    enum: [
      'Suspicious Person',
      'Theft/Robbery',
      'Vandalism',
      'Drug Activity',
      'Harassment',
      'Safety Hazard',
      'Unauthorized Access',
      'Other'
    ],
    default: 'Other'
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'medium'
  },
  status: {
    type: String,
    enum: ['verified', 'needs_review', 'unverified', 'active', 'investigating', 'resolved', 'false_alarm', 'pending_review', 'real'],
    default: 'needs_review'
  },
  verificationTag: {
    type: String,
    enum: ['Verified', 'Needs Review', 'Unverified'],
    default: 'Needs Review'
  },
  aiAnalysis: {
    confidence: Number,
    details: String,
    verificationTag: String
  },
  resolution: String,
  resolvedBy: String,
  resolvedAt: Date,
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Add indexes for faster queries
alertSchema.index({ createdAt: -1 });
alertSchema.index({ status: 1 });
alertSchema.index({ verificationTag: 1 });
alertSchema.index({ priority: 1 });
alertSchema.index({ alertId: 1 });

module.exports = mongoose.model('Alert', alertSchema);