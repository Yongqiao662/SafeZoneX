const mongoose = require('mongoose');

const walkSessionSchema = new mongoose.Schema({
  sessionId: {
    type: String,
    required: true,
    unique: true
  },
  requesterId: {
    type: String,
    required: true
  },
  partnerId: {
    type: String,
    required: false
  },
  status: {
    type: String,
    enum: ['pending', 'matched', 'active', 'completed', 'cancelled'],
    default: 'pending'
  },
  startLocation: {
    latitude: Number,
    longitude: Number,
    address: String
  },
  endLocation: {
    latitude: Number,
    longitude: Number,
    address: String
  },
  plannedRoute: {
    coordinates: [[Number]], // Array of [lat, lng] points
    distance: Number, // in meters
    estimatedTime: Number // in minutes
  },
  actualRoute: {
    coordinates: [[Number]],
    distance: Number,
    actualTime: Number
  },
  faceVerification: {
    requesterVerified: {
      type: Boolean,
      default: false
    },
    partnerVerified: {
      type: Boolean,
      default: false
    },
    requesterConfidence: Number,
    partnerConfidence: Number,
    verificationTimestamp: Date
  },
  realTimeTracking: {
    lastUpdated: Date,
    currentLocation: {
      latitude: Number,
      longitude: Number
    },
    deviationAlerts: [{
      timestamp: Date,
      deviation: Number, // meters from planned route
      action: String
    }]
  },
  safetyMetrics: {
    routeSafetyScore: Number,
    timeOfDay: String,
    weatherConditions: String,
    crowdDensity: String
  },
  completionDetails: {
    completedAt: Date,
    rating: {
      requesterRating: Number,
      partnerRating: Number,
      comments: String
    },
    safeArrival: Boolean
  },
  emergencyEvents: [{
    timestamp: Date,
    type: String,
    location: {
      latitude: Number,
      longitude: Number
    },
    resolved: Boolean
  }]
}, {
  timestamps: true
});

walkSessionSchema.index({ requesterId: 1, createdAt: -1 });
walkSessionSchema.index({ partnerId: 1, createdAt: -1 });
walkSessionSchema.index({ status: 1 });

module.exports = mongoose.model('WalkSession', walkSessionSchema);
