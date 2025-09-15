const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    unique: true
  },
  email: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  phone: {
    type: String,
    required: true
  },
  studentId: {
    type: String,
    required: true,
    unique: true
  },
  profilePicture: {
    type: String, // Base64 or file path
    required: false
  },
  faceDescriptors: {
    type: [Number], // Face recognition descriptors
    required: false
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  verificationScore: {
    type: Number,
    default: 0
  },
  safetyRating: {
    type: Number,
    default: 5.0,
    min: 0,
    max: 10
  },
  totalWalks: {
    type: Number,
    default: 0
  },
  emergencyContacts: [{
    name: String,
    phone: String,
    relationship: String
  }],
  location: {
    latitude: Number,
    longitude: Number,
    lastUpdated: Date
  },
  isActive: {
    type: Boolean,
    default: true
  },
  joinedAt: {
    type: Date,
    default: Date.now
  },
  lastSeen: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for geospatial queries
userSchema.index({ "location.latitude": 1, "location.longitude": 1 });

module.exports = mongoose.model('User', userSchema);
