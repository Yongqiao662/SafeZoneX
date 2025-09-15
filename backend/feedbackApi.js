const express = require('express');
const router = express.Router();
const Feedback = require('./models/Feedback');

// Helper: Check if report is confirmed real (2+ unique users)
async function checkConfirmedReal(report_id) {
  const feedbacks = await Feedback.find({ report_id, feedback: 'real' });
  const uniqueUsers = new Set(feedbacks.map(f => f.user_id || 'anon'));
  return uniqueUsers.size >= 2;
}

// POST /api/feedback
router.post('/feedback', async (req, res) => {
  try {
    const { report_id, report_text, feedback, location, timestamp, user_id } = req.body;
    if (!report_id || !report_text || !feedback) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    const fb = new Feedback({ report_id, report_text, feedback, location, timestamp, user_id });
    await fb.save();
    // Tier 2: Confirmed real if 2+ unique users
    if (feedback === 'real') {
      const confirmed = await checkConfirmedReal(report_id);
      if (confirmed) {
        await Feedback.updateMany({ report_id }, { confirmed_real: true });
      }
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
