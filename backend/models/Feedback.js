const mongoose = require('mongoose');

const FeedbackSchema = new mongoose.Schema({
  report_id: { type: String, required: true },
  report_text: { type: String, required: true },
  feedback: { type: String, enum: ['real', 'fake'], required: true },
  location: { type: String },
  timestamp: { type: Date, default: Date.now },
  user_id: { type: String },
  confirmed_real: { type: Boolean, default: false }
});

module.exports = mongoose.model('Feedback', FeedbackSchema);
