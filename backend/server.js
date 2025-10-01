const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');

const Alert = require('./models/Alert');
const Feedback = require('./models/Feedback');
const User = require('./models/User');

const submittedReports = new Set();

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
    credentials: true
  },
  transports: ['websocket', 'polling'],
  allowEIO3: true
});

app.use(express.json({ limit: '10mb' }));

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  next();
});

// Serve static files (for dashboard.html)
app.use(express.static('public'));

// Or serve dashboard.html directly
app.get('/dashboard.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard.html'));
});

const mongoURI = process.env.MONGODB_URI;
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  logger.info('📦 Connected to MongoDB successfully');
}).catch(error => {
  logger.error('❌ MongoDB connection error:', error);
  process.exit(1);
});

let alertsCache = new Map();

// IMPROVED AI confidence calculation
function calculateConfidence(description, evidenceImages, alertType) {
  let confidence = 40;
  
  const text = description?.toLowerCase() || '';
  
  const criticalKeywords = /theft|robbery|stolen|steal|attack|assault|weapon|knife|gun|rape|murder|kidnap|abduct|drug deal|overdose|unconscious/i;
  if (criticalKeywords.test(text)) {
    confidence += 35;
  }
  
  const highKeywords = /suspicious person|following|loiter|harassment|vandalism|graffiti|damage|broken|fight|threat|intimidat|unsafe|hazard|leak|fire|smoke/i;
  if (highKeywords.test(text)) {
    confidence += 25;
  }
  
  const mediumKeywords = /concern|worry|strange|unusual|unauthorized|trespass|noise|disturbance/i;
  if (mediumKeywords.test(text)) {
    confidence += 15;
  }
  
  const infrastructureKeywords = /broken|faulty|not working|malfunctioning|damaged|leaking|blocked|unsafe|light|elevator|door lock|fire alarm|air conditioning|security camera|emergency exit|window|garbage|electrical|flood|handrail|street light|um accommodation|kk8/i;
  if (infrastructureKeywords.test(text)) {
    confidence += 20;
  }
  
  const fakeKeywords = /win|prize|click here|free money|congratulations|lottery|\$\d+|limited time offer|act now|claim|verify account|suspended|click link|download|sign up now/i;
  if (fakeKeywords.test(text)) {
    confidence -= 40;
  }
  
  const testKeywords = /test|testing|demo|sample|example|trying|check|dummy/i;
  if (testKeywords.test(text)) {
    confidence -= 35;
  }
  
  if (text.length > 80) confidence += 10;
  if (text.length > 150) confidence += 10;
  
  if (evidenceImages && evidenceImages.length > 0) {
    confidence += 15;
  }
  
  const highPriorityTypes = ['Theft/Robbery', 'Drug Activity', 'Harassment', 'Safety Hazard'];
  if (highPriorityTypes.includes(alertType)) {
    confidence += 10;
  }
  
  confidence = Math.max(15, Math.min(95, confidence));
  
  return confidence;
}

function determineStatusAndPriority(confidence, alertType, description) {
  let status, verificationTag, priority;
  const text = description?.toLowerCase() || '';
  
  if (confidence >= 70) {
    status = 'verified';
    verificationTag = 'Verified';
  } else if (confidence >= 30) {
    status = 'needs_review';
    verificationTag = 'Needs Review';
  } else {
    status = 'unverified';
    verificationTag = 'Unverified';
  }
  
  const criticalWords = /weapon|gun|knife|attack|assault|rape|murder|kidnap|overdose|unconscious|emergency|critical|urgent/i;
  const highWords = /theft|robbery|drug|harassment|following|stalk|threat|unsafe|fire|gas leak|chemical spill/i;
  const mediumWords = /suspicious|vandalism|damage|broken|unauthorized|trespass/i;
  
  if (criticalWords.test(text) || (confidence >= 80 && ['Theft/Robbery', 'Drug Activity', 'Harassment'].includes(alertType))) {
    priority = 'critical';
  } else if (highWords.test(text) || (confidence >= 65 && ['Safety Hazard', 'Unauthorized Access'].includes(alertType))) {
    priority = 'high';
  } else if (mediumWords.test(text) || confidence >= 50) {
    priority = 'medium';
  } else {
    priority = 'low';
  }
  
  return { status, verificationTag, priority };
}

app.post('/api/report', async (req, res) => {
  try {
    const reportKey = `${req.body.userId}_${req.body.description}_${req.body.location.latitude}_${req.body.location.longitude}`;
    
    if (submittedReports.has(reportKey)) {
      console.log('🚫 DUPLICATE BLOCKED:', reportKey);
      return res.json({ success: false, error: 'Duplicate submission blocked' });
    }
    
    submittedReports.add(reportKey);
    setTimeout(() => submittedReports.delete(reportKey), 10000);
    
    console.log('📝 Report submission:', JSON.stringify(req.body, null, 2));

    const {
      userId,
      userName,
      userPhone,
      location,
      description,
      evidenceImages,
      alertType,
      priority: requestedPriority
    } = req.body;

    if (!userId || !userName || !userPhone) {
      console.log('❌ Missing user fields');
      return res.status(400).json({ success: false, error: 'Missing required user fields' });
    }
    
    if (!location || typeof location.latitude !== 'number' || typeof location.longitude !== 'number') {
      console.log('❌ Invalid location:', location);
      return res.status(400).json({ success: false, error: 'Missing or invalid location' });
    }

    const reportId = uuidv4();
    
    let confidence = calculateConfidence(description, evidenceImages, alertType);
    
    console.log(`🎯 AI Confidence: ${confidence}% for "${description?.substring(0, 60)}..."`);

    const { status, verificationTag, priority } = determineStatusAndPriority(
      confidence, 
      alertType, 
      description
    );

    let aiAnalysisDetails = '';
    if (confidence >= 70) {
      aiAnalysisDetails = `High confidence report - Verified as legitimate. Priority: ${priority}`;
    } else if (confidence >= 30) {
      aiAnalysisDetails = `Medium confidence - Needs manual review by security team. Priority: ${priority}`;
    } else {
      aiAnalysisDetails = `Low confidence - Requires verification. May be spam or unclear report. Priority: ${priority}`;
    }

    const alertData = {
      alertId: reportId,
      userId,
      userName,
      userPhone,
      location: {
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address || '',
        campus: location.campus || 'University Malaya'
      },
      description: description || '',
      evidenceImages: Array.isArray(evidenceImages) ? evidenceImages : [],
      alertType: alertType || 'Other',
      priority,
      status,
      verificationTag,
      aiAnalysis: {
        confidence,
        details: aiAnalysisDetails,
        verificationTag
      },
      createdAt: new Date()
    };

    console.log('💾 Saving report:', {
      reportId,
      status,
      verificationTag,
      priority,
      confidence
    });

    const newAlert = new Alert(alertData);
    await newAlert.save();
    alertsCache.set(reportId, newAlert);

    console.log('✅ Report saved successfully');
    logger.info(`🚨 New report: ${reportId} (${status}, ${verificationTag}, confidence: ${confidence}%)`);

    res.json({ 
      success: true, 
      reportId,
      status,
      verificationTag,
      aiAnalysis: alertData.aiAnalysis,
      message: 'Report submitted successfully' 
    });

    const reportPayload = {
      alertId: reportId,
      userId,
      userName,
      userPhone,
      alertType,
      status,
      verificationTag,
      aiAnalysis: alertData.aiAnalysis,
      location: alertData.location,
      description,
      priority,
      createdAt: new Date()
    };
    
    io.to('security_dashboard').emit('report_update', reportPayload);
    console.log(`📢 Sent to dashboard - ${verificationTag} (${confidence}%), Priority: ${priority}`);

  } catch (error) {
    console.error('❌ Report submission error:', error);
    logger.error('Error submitting report:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to submit report',
      message: error.message 
    });
  }
});

app.get('/api/reports', async (req, res) => {
  try {
    console.log('📊 Dashboard fetching all reports');
    
    const reports = await Alert.find({})
      .sort({ createdAt: -1 })
      .limit(100);

    console.log(`📋 Found ${reports.length} total reports for dashboard`);

    const transformedReports = reports.map(report => ({
      id: report.alertId,
      alertId: report.alertId,
      userId: report.userId,
      userName: report.userName,
      userPhone: report.userPhone,
      alertType: report.alertType,
      description: report.description,
      location: report.location,
      status: report.status,
      verificationTag: report.verificationTag || 'Needs Review',
      priority: report.priority,
      createdAt: report.createdAt,
      aiAnalysis: report.aiAnalysis,
      evidenceImages: report.evidenceImages || []
    }));

    res.json({
      success: true,
      count: transformedReports.length,
      reports: transformedReports
    });

  } catch (error) {
    console.error('❌ Error fetching reports:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch reports'
    });
  }
});

app.get('/api/reports/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const report = await Alert.findOne({ alertId: id });

    if (!report) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    res.json({
      success: true,
      report: {
        id: report.alertId,
        alertId: report.alertId,
        userId: report.userId,
        userName: report.userName,
        userPhone: report.userPhone,
        alertType: report.alertType,
        description: report.description,
        location: report.location,
        status: report.status,
        verificationTag: report.verificationTag || 'Needs Review',
        priority: report.priority,
        createdAt: report.createdAt,
        aiAnalysis: report.aiAnalysis,
        evidenceImages: report.evidenceImages || []
      }
    });
  } catch (error) {
    console.error('❌ Error fetching specific report:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch report' });
  }
});

app.put('/api/reports/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, resolution, resolvedBy } = req.body;
    
    const validStatuses = ['active', 'investigating', 'resolved', 'false_alarm', 'pending_review', 'real', 'verified', 'needs_review', 'unverified'];
    
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, error: 'Invalid status' });
    }

    const updatedReport = await Alert.findOneAndUpdate(
      { alertId: id },
      { 
        status: status,
        resolution: resolution || '',
        resolvedBy: resolvedBy || '',
        resolvedAt: status === 'resolved' ? new Date() : null,
        updatedAt: new Date()
      },
      { new: true }
    );

    if (!updatedReport) {
      return res.status(404).json({ success: false, error: 'Report not found' });
    }

    io.to('security_dashboard').emit('report_status_updated', {
      alertId: id,
      status: status,
      resolvedBy: resolvedBy,
      resolvedAt: updatedReport.resolvedAt
    });

    res.json({ success: true, message: 'Report status updated successfully' });
  } catch (error) {
    console.error('❌ Error updating report status:', error);
    res.status(500).json({ success: false, error: 'Failed to update report status' });
  }
});

io.use((socket, next) => {
  socket.user = { id: 'dev_user', role: 'security', name: 'Dev User' };
  next();
});

io.on('connection', (socket) => {
  logger.info(`🔌 Client connected: ${socket.id}`);

  if (socket.user.role === 'security') {
    socket.join('security_dashboard');
  }

  socket.on('join_room', (data) => {
    const room = data.room || 'security_dashboard';
    socket.join(room);
    logger.info(`🔥 Client ${socket.id} joined room: ${room}`);
  });

  // SOS Alert - Broadcast to all connected friends
  socket.on('sos_alert', (data) => {
    logger.info(`🆘 SOS Alert received from ${data.userName}:`, data);
    
    // Store SOS alert in memory (or database)
    const sosAlert = {
      id: uuidv4(),
      ...data,
      socketId: socket.id,
      status: 'active',
      acknowledgedBy: [],
      createdAt: new Date().toISOString()
    };
    
    alertsCache.set(sosAlert.id, sosAlert);
    
    // Broadcast to ALL connected clients (friends)
    io.emit('friend_sos_alert', sosAlert);
    
    // Also send to security dashboard
    io.to('security_dashboard').emit('security_sos_alert', sosAlert);
    
    logger.info(`📡 SOS broadcasted to all friends and security`);
  });

  // SOS Location Update - Real-time location sharing
  socket.on('sos_location_update', (data) => {
    logger.info(`📍 Location update from ${data.userId}`);
    
    // Broadcast location update to all friends
    io.emit('friend_location_update', {
      ...data,
      socketId: socket.id,
      timestamp: new Date().toISOString()
    });
  });

  // Friend acknowledges SOS
  socket.on('sos_acknowledge', (data) => {
    logger.info(`✅ SOS acknowledged by friend: ${data.friendName}`);
    
    // Find the SOS alert
    const alertId = data.alertId;
    const sosAlert = alertsCache.get(alertId);
    
    if (sosAlert) {
      sosAlert.acknowledgedBy.push({
        friendId: data.friendId,
        friendName: data.friendName,
        timestamp: new Date().toISOString()
      });
      
      // Notify the person in distress
      io.to(sosAlert.socketId).emit('sos_acknowledged', {
        friendName: data.friendName,
        message: `${data.friendName} has been notified and is checking on you`
      });
      
      logger.info(`💬 Acknowledgment sent back to SOS user`);
    }
  });

  // SOS Ended
  socket.on('sos_ended', (data) => {
    logger.info(`✅ SOS ended by ${data.userId}`);
    
    // Broadcast to all friends
    io.emit('friend_sos_ended', {
      ...data,
      socketId: socket.id,
      timestamp: new Date().toISOString()
    });
    
    // Clean up alerts from this user
    for (let [key, alert] of alertsCache.entries()) {
      if (alert.userId === data.userId) {
        alertsCache.delete(key);
      }
    }
  });

  socket.on('disconnect', () => {
    logger.info(`🔌 Client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  logger.info(`🚀 Server running on http://localhost:${PORT}`);
  logger.info(`📊 Dashboard available at: http://localhost:${PORT}/dashboard.html`);
});