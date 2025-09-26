// Adjust dotenv configuration to use absolute path
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
const jwt = require('jsonwebtoken');

// Import models
const Alert = require('./models/Alert');
const Feedback = require('./models/Feedback');
const User = require('./models/User');

// ADDED: Duplicate prevention
const submittedReports = new Set();

// Configure logging
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

// Add CORS middleware for web dashboard
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  next();
});

// MongoDB connection
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

// Active alerts cache
let alertsCache = new Map();

// FIXED: Better AI confidence calculation
function calculateConfidence(description, evidenceImages, alertType) {
  let confidence = 30;
  
  if (description && description.length > 50) confidence += 15;
  if (description && description.length > 100) confidence += 10;
  
  const realKeywords = /theft|robbery|vandalism|harassment|drug|assault|suspicious person|emergency|danger|weapon|fight|attack|steal|stolen|crime/i;
  const fakeKeywords = /test|fake|demo|sample|example|trying|check/i;
  
  if (description && realKeywords.test(description)) {
    confidence += 20;
  }
  
  if (description && fakeKeywords.test(description)) {
    confidence -= 30;
  }
  
  if (evidenceImages && evidenceImages.length > 0) confidence += 15;
  
  if (alertType && alertType !== 'Other') confidence += 10;
  
  if (confidence > 85) confidence = 85;
  if (confidence < 20) confidence = 20;
  
  return confidence;
}

// API to submit a report
app.post('/api/report', async (req, res) => {
  try {
    const reportKey = `${req.body.userId}_${req.body.description}_${req.body.location.latitude}_${req.body.location.longitude}`;
    
    if (submittedReports.has(reportKey)) {
      console.log('🚫 DUPLICATE BLOCKED:', reportKey);
      return res.json({ success: false, error: 'Duplicate submission blocked' });
    }
    
    submittedReports.add(reportKey);
    setTimeout(() => submittedReports.delete(reportKey), 10000);
    
    console.log('📝 Report submission request body:', JSON.stringify(req.body, null, 2));

    const {
      userId,
      userName,
      userPhone,
      location,
      description,
      evidenceImages,
      alertType,
      priority
    } = req.body;

    console.log('📋 Extracted fields:', {
      userId,
      userName,
      userPhone,
      location,
      description: description?.substring(0, 50) + '...',
      hasImages: evidenceImages?.length > 0,
      alertType,
      priority
    });

    if (!userId || !userName || !userPhone) {
      console.log('❌ Missing user fields:', { userId: !!userId, userName: !!userName, userPhone: !!userPhone });
      return res.status(400).json({ success: false, error: 'Missing required user fields' });
    }
    
    if (!location || typeof location.latitude !== 'number' || typeof location.longitude !== 'number') {
      console.log('❌ Invalid location:', location);
      return res.status(400).json({ success: false, error: 'Missing or invalid location' });
    }

    const reportId = uuidv4();
    
    // Calculate AI confidence
    let confidence = calculateConfidence(description, evidenceImages, alertType);
    
    console.log(`🎯 Calculated confidence: ${confidence}% for description: "${description}"`);

    // Determine status based on confidence
    let status = 'active';
    let aiAnalysis = {
      confidence: confidence,
      details: ''
    };
    
    let validPriority = 'medium';
    if (priority === 'normal') {
      validPriority = 'medium';
    } else if (['low', 'medium', 'high', 'critical'].includes(priority)) {
      validPriority = priority;
    }

    // FIXED: Status logic based on confidence
    if (confidence >= 70) {
      status = 'real';
      aiAnalysis.details = 'High confidence - appears to be legitimate incident';
    } else if (confidence >= 50) {
      status = 'active';
      aiAnalysis.details = 'Under investigation - needs verification';
    } else {
      status = 'pending_review';
      aiAnalysis.details = 'Low confidence - manual review required';
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
      priority: validPriority,
      status,
      aiAnalysis,
      createdAt: new Date()
    };

    console.log('💾 Saving alert with status:', status, 'priority:', validPriority, 'confidence:', confidence);

    const newAlert = new Alert(alertData);
    await newAlert.save();
    alertsCache.set(reportId, newAlert);

    console.log('✅ Report saved successfully:', reportId);
    logger.info(`🚨 New report submitted: ${reportId} (${status})`);

    // ALWAYS return AI analysis to mobile app
    res.json({ 
      success: true, 
      reportId,
      status,
      aiAnalysis,
      message: 'Report submitted successfully' 
    });

    // FIXED: Only emit to dashboard if confidence >= 50%
    if (confidence >= 50) {
      const reportPayload = {
        alertId: reportId,
        userId,
        userName,
        alertType,
        status,
        aiAnalysis,
        location: alertData.location,
        description,
        priority: validPriority,
        createdAt: new Date()
      };
      
      io.to('security_dashboard').emit('report_update', reportPayload);
      console.log(`📢 Shown on dashboard - Status: ${status}, Confidence: ${confidence}%`);
    } else {
      console.log(`🚫 Hidden from dashboard (confidence ${confidence}% < 50%) - Status: ${status}`);
    }

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

// GET all reports for dashboard - FIXED: Only return reports with confidence >= 50%
app.get('/api/reports', async (req, res) => {
  try {
    console.log('📊 Dashboard fetching all reports');
    
    const reports = await Alert.find({
      'aiAnalysis.confidence': { $gte: 50 }
    })
      .sort({ createdAt: -1 })
      .limit(100);

    console.log(`📋 Found ${reports.length} reports with confidence >= 50% for dashboard`);

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
    console.error('❌ Error fetching reports for dashboard:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch reports'
    });
  }
});

// GET specific report by ID
app.get('/api/reports/:id', async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔍 Fetching specific report:', id);

    const report = await Alert.findOne({ alertId: id });

    if (!report) {
      return res.status(404).json({
        success: false,
        error: 'Report not found'
      });
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
        priority: report.priority,
        createdAt: report.createdAt,
        aiAnalysis: report.aiAnalysis,
        evidenceImages: report.evidenceImages || []
      }
    });

  } catch (error) {
    console.error('❌ Error fetching specific report:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch report'
    });
  }
});

// UPDATE report status
app.put('/api/reports/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, resolution, resolvedBy } = req.body;
    
    console.log('🔄 Dashboard updating report status:', id, 'to', status);

    const validStatuses = ['active', 'investigating', 'resolved', 'false_alarm', 'pending_review', 'real'];
    
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Must be: ' + validStatuses.join(', ')
      });
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
      return res.status(404).json({
        success: false,
        error: 'Report not found'
      });
    }

    console.log('✅ Report status updated successfully via dashboard');

    const updatePayload = {
      alertId: id,
      status: status,
      resolvedBy: resolvedBy,
      resolvedAt: updatedReport.resolvedAt
    };
    io.to('security_dashboard').emit('report_status_updated', updatePayload);

    res.json({
      success: true,
      message: 'Report status updated successfully',
      report: {
        id: updatedReport.alertId,
        alertId: updatedReport.alertId,
        status: updatedReport.status,
        resolvedBy: updatedReport.resolvedBy,
        resolvedAt: updatedReport.resolvedAt
      }
    });

  } catch (error) {
    console.error('❌ Error updating report status via dashboard:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update report status'
    });
  }
});

// GET dashboard statistics
app.get('/api/reports/stats', async (req, res) => {
  try {
    console.log('📈 Fetching dashboard statistics');

    const [
      totalReports,
      activeReports, 
      resolvedReports,
      recentReports
    ] = await Promise.all([
      Alert.countDocuments({ 'aiAnalysis.confidence': { $gte: 50 } }),
      Alert.countDocuments({ status: 'active', 'aiAnalysis.confidence': { $gte: 50 } }),
      Alert.countDocuments({ status: 'resolved', 'aiAnalysis.confidence': { $gte: 50 } }),
      Alert.countDocuments({ 
        createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
        'aiAnalysis.confidence': { $gte: 50 }
      })
    ]);

    const alertTypeStats = await Alert.aggregate([
      {
        $match: { 'aiAnalysis.confidence': { $gte: 50 } }
      },
      {
        $group: {
          _id: '$alertType',
          count: { $sum: 1 }
        }
      }
    ]);

    const stats = {
      totalReports,
      activeReports,
      resolvedReports, 
      recentReports,
      alertTypeBreakdown: alertTypeStats
    };

    console.log('📊 Dashboard statistics:', stats);

    res.json({
      success: true,
      stats: stats
    });

  } catch (error) {
    console.error('❌ Error fetching dashboard statistics:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch dashboard statistics'
    });
  }
});

// Import required modules for AI analysis
const fs = require('fs');
const { spawn } = require('child_process');

// Feedback loop function
function requestFeedback(alert) {
  logger.info(`🔄 Requesting feedback for report: ${alert.alertId}`);
  io.emit('feedback_request', {
    alertId: alert.alertId,
    message: 'Please provide feedback on this report.'
  });
}

// DEVELOPMENT ONLY: Disable JWT authentication for Socket.IO
io.use((socket, next) => {
  socket.user = {
    id: 'dev_user',
    role: 'security',
    name: 'Dev User'
  };
  next();
});

io.on('connection', (socket) => {
  logger.info(`🔌 Client connected: ${socket.id} (User: ${socket.user.id})`);

  if (socket.user.role === 'student') {
    socket.join(`student_${socket.user.id}`);
    logger.info(`👨‍🎓 Student joined room: student_${socket.user.id}`);
  } else if (socket.user.role === 'security') {
    socket.join('security_dashboard');
    logger.info(`🔐 Security joined room: security_dashboard`);
  }

  socket.on('join_room', (data) => {
    const room = data.room || 'security_dashboard';
    socket.join(room);
    logger.info(`📥 Client ${socket.id} joined room: ${room}`);
  });

  socket.on('report_update', (data) => {
    if (socket.user.role === 'student') {
      io.to(`student_${socket.user.id}`).emit('report_update', data);
    } else if (socket.user.role === 'security') {
      io.to('security_dashboard').emit('report_update', data);
    }
  });

  socket.on('feedback_response', async ({ alertId, confirmed }) => {
    try {
      await Feedback.create({
        report_id: alertId,
        feedback: confirmed ? 'real' : 'fake',
        user_id: socket.user.id,
        timestamp: new Date()
      });

      const newStatus = confirmed ? 'real' : 'false_alarm';
      await Alert.updateOne(
        { alertId },
        { $set: { status: newStatus } }
      );

      if (socket.user.role === 'student') {
        io.to(`student_${socket.user.id}`).emit('report_update', { alertId, status: newStatus });
      } else if (socket.user.role === 'security') {
        io.to('security_dashboard').emit('report_update', { alertId, status: newStatus });
      }
    } catch (error) {
      logger.error('Error handling feedback_response:', error);
    }
  });

  socket.on('disconnect', () => {
    logger.info(`🔌 Client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  logger.info(`🚀 Server running on http://localhost:${PORT}`);
});