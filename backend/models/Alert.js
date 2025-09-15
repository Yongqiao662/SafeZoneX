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
  alertType: {
    type: String,
    enum: ['emergency', 'medical', 'security', 'harassment', 'accident', 'other'],
    default: 'emergency'
  },
  status: {
    type: String,
    enum: ['active', 'acknowledged', 'resolved', 'false_alarm'],
    default: 'active'
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'high'
  },
  location: {
    latitude: {
      type: Number,
      required: true
    },
    longitude: {
      type: Number,
      required: true
    },
    address: {
      type: String,
      required: false
    },
    campus: {
      type: String,
      default: 'University Malaya'
    }
  },
  description: {
    type: String,
    required: false
  },
  evidenceImages: [{
    imageData: String, // Base64 encoded
    timestamp: Date,
    verified: Boolean,
    aiAnalysis: {
      genuineScore: Number,
      manipulationDetected: Boolean,
      analysisDetails: String
    }
  }],
  faceVerification: {
    verified: {
      type: Boolean,
      default: false
    },
    confidence: {
      type: Number,
      default: 0
    },
    timestamp: Date,
    matchScore: Number
  },
  timeline: [{
    action: String,
    timestamp: Date,
    performer: String,
    details: String
  }],
  acknowledgedBy: {
    type: String,
    required: false
  },
  acknowledgedAt: {
    type: Date,
    required: false
  },
  resolvedBy: {
    type: String,
    required: false
  },
  resolvedAt: {
    type: Date,
    required: false
  },
  responseTime: {
    type: Number, // in seconds
    required: false
  },
  emergencyContacts: [{
    name: String,
    phone: String,
    notified: Boolean,
    notifiedAt: Date
  }],
  aiAnalysis: {
    reportGenuineness: {
      score: Number, // 0-100
      factors: [String],
      riskLevel: String
    },
    locationVerification: {
      plausible: Boolean,
      score: Number,
      reasoning: String
    },
    behaviorAnalysis: {
      consistent: Boolean,
      anomalies: [String]
    }
  },
  metadata: {
    deviceInfo: String,
    appVersion: String,
    networkInfo: String,
    batteryLevel: Number
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
alertSchema.index({ userId: 1, createdAt: -1 });
alertSchema.index({ status: 1, createdAt: -1 });
alertSchema.index({ "location.latitude": 1, "location.longitude": 1 });
alertSchema.index({ alertType: 1, priority: 1 });

module.exports = mongoose.model('Alert', alertSchema);
