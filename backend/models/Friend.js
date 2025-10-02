const mongoose = require('mongoose');

const friendSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    ref: 'User'
  },
  friendId: {
    type: String,
    required: true,
    ref: 'User'
  },
  friendName: {
    type: String,
    required: true
  },
  friendEmail: {
    type: String,
    required: true
  },
  friendUsername: {
    type: String,
    required: true
  },
  profileColor: {
    type: String,
    default: 'blue'
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'blocked'],
    default: 'pending'
  },
  addedAt: {
    type: Date,
    default: Date.now
  },
  lastInteraction: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Compound index to prevent duplicate friendships
friendSchema.index({ userId: 1, friendId: 1 }, { unique: true });

module.exports = mongoose.model('Friend', friendSchema);
