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
const io = socketIo(server);

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

// API to submit a report - CORRECTED WITH PROPER ENUM VALUES
app.post('/api/report', async (req, res) => {
  try {
    console.log('📝 Report submission request body:', JSON.stringify(req.body, null, 2));

    // Extract and validate required fields
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

    // Validate required fields
    if (!userId || !userName || !userPhone) {
      console.log('❌ Missing user fields:', { userId: !!userId, userName: !!userName, userPhone: !!userPhone });
      return res.status(400).json({ success: false, error: 'Missing required user fields' });
    }
    
    if (!location || typeof location.latitude !== 'number' || typeof location.longitude !== 'number') {
      console.log('❌ Invalid location:', location);
      return res.status(400).json({ success: false, error: 'Missing or invalid location' });
    }

    const reportId = uuidv4();
    let initialConfidence = 50;
    if (description && description.length > 20) initialConfidence += 10;
    if (description && /theft|robbery|vandalism|harassment|drug/i.test(description)) initialConfidence += 10;
    if (evidenceImages && evidenceImages.length > 0) initialConfidence += 10;
    if (initialConfidence > 90) initialConfidence = 90;

    // FIXED: Use proper enum values from your schema
    let status = 'active'; // Default status from schema
    let aiAnalysis = null;
    
    // Map priority values correctly
    let validPriority = 'high'; // Default priority from schema
    if (priority === 'normal') {
      validPriority = 'medium'; // Map 'normal' to 'medium' which exists in enum
    } else if (['low', 'medium', 'high', 'critical'].includes(priority)) {
      validPriority = priority;
    }

    // Build alert object for MongoDB
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
      alertType: alertType || 'Other', // Use 'Other' as default (matches enum)
      priority: validPriority, // Use mapped priority value
      status, // Use 'active' status (matches enum)
      createdAt: new Date()
    };

    // Process based on confidence level
    if (initialConfidence > 70) {
      status = 'real';
      aiAnalysis = {
        confidence: initialConfidence,
        details: 'High confidence (auto-classified as real)'
      };
      alertData.status = status;
      alertData.aiAnalysis = aiAnalysis;
    } else if (initialConfidence >= 50 && initialConfidence <= 70) {
      status = 'active'; // Keep as active for pending AI analysis
      aiAnalysis = {
        confidence: initialConfidence,
        details: 'Pending AI analysis'
      };
      alertData.status = status;
      alertData.aiAnalysis = aiAnalysis;
    } else {
      status = 'pending_review'; // This matches your enum
      aiAnalysis = {
        confidence: initialConfidence,
        details: 'Low confidence, pending manual review'
      };
      alertData.status = status;
      alertData.aiAnalysis = aiAnalysis;
    }

    console.log('💾 Saving alert with status:', status, 'priority:', validPriority);

    // Save to database
    const newAlert = new Alert(alertData);
    await newAlert.save();
    alertsCache.set(reportId, newAlert);

    console.log('✅ Report saved successfully:', reportId);
    logger.info(`🚨 New report submitted: ${reportId} (${status})`);

    // Return success response
    res.json({ 
      success: true, 
      reportId,
      status,
      message: 'Report submitted successfully' 
    });

    // Emit to websocket: send to security_dashboard room and broadcast to all
    const reportPayload = {
      alertId: reportId,
      userId,
      userName,
      alertType,
      status,
      aiAnalysis,
      location: alertData.location,
      description
    };
    io.to('security_dashboard').emit('report_update', reportPayload);
    io.emit('report_update', reportPayload);

    // Start AI analysis if needed (don't wait for it)
    if (initialConfidence >= 50 && initialConfidence <= 70) {
      analyzeReport(newAlert).catch(err => 
        console.log('AI analysis error (non-blocking):', err)
      );
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

// GET all reports for dashboard
app.get('/api/reports', async (req, res) => {
  try {
    console.log('📊 Dashboard fetching all reports');
    
    const reports = await Alert.find({})
      .sort({ createdAt: -1 })
      .limit(100);

    console.log(`📋 Found ${reports.length} reports for dashboard`);

    // Transform data to match dashboard expectations
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

// UPDATE report status (for dashboard to resolve reports)
app.put('/api/reports/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, resolution, resolvedBy } = req.body;
    
    console.log('🔄 Dashboard updating report status:', id, 'to', status);

    const validStatuses = ['active', 'investigating', 'resolved', 'false_alarm', 'pending_review'];
    
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

    // Emit status update to all connected clients
    const updatePayload = {
      alertId: id,
      status: status,
      resolvedBy: resolvedBy,
      resolvedAt: updatedReport.resolvedAt
    };
    io.to('security_dashboard').emit('report_status_updated', updatePayload);
    io.emit('report_status_updated', updatePayload);

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
      Alert.countDocuments({}),
      Alert.countDocuments({ status: 'active' }),
      Alert.countDocuments({ status: 'resolved' }),
      Alert.countDocuments({ 
        createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
      })
    ]);

    const alertTypeStats = await Alert.aggregate([
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

// AI analysis function - FIXED FOR CONSISTENT STATUS
async function analyzeReport(alert) {
  try {
    logger.info(`🤖 Analyzing report: ${alert.alertId}`);

    // Use high accuracy model and vectorizer
    const scriptPath = path.resolve(__dirname, 'models', 'quick_test.py');
    const modelPath = path.resolve(__dirname, 'safety_report_classifier_high_accuracy.pkl');
    const vectorizerPath = path.resolve(__dirname, 'tfidf_vectorizer_high_accuracy.pkl');

    // Prepare input data for the Python script
    const inputData = JSON.stringify({
      description: alert.description,
      location: alert.location,
      evidenceImages: alert.evidenceImages
    });

    // Spawn a Python process to run the analysis
    const pythonProcess = spawn('python', [scriptPath, modelPath, vectorizerPath]);

    let result = '';
    pythonProcess.stdout.on('data', (data) => {
      result += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      logger.error(`Python error: ${data.toString()}`);
    });

    pythonProcess.on('close', async (code) => {
      if (code === 0) {
        const analysisResult = JSON.parse(result);
        const confidence = analysisResult.confidence;
        let status = 'pending_review';
        let sendToDashboard = false;
        let details = analysisResult.details;

        // FIXED: Consistent status logic - no more 'likely_real'
        if (confidence >= 60) {
          status = 'real';
          sendToDashboard = true;
          details = 'AI verified: legitimate safety report';
        } else if (confidence >= 40) {
          status = 'real';
          sendToDashboard = true;
          details = `Confidence ${confidence}%: classified as real`;
        } else {
          status = 'investigating';
          sendToDashboard = true;
          details = 'Under review - manual verification required';
        }

        alert.status = status;
        // Patch: Only set aiAnalysis.confidence and details as top-level fields
        alert.aiAnalysis = alert.aiAnalysis || {};
        alert.aiAnalysis.confidence = confidence;
        alert.aiAnalysis.details = details;
        await alert.save();

        logger.info(`✅ Report analysis complete: ${alert.alertId} (${status})`);

        // Send to dashboard with new status
        if (sendToDashboard) {
          const reportPayload = {
            alertId: alert.alertId,
            userId: alert.userId,
            userName: alert.userName,
            alertType: alert.alertType,
            status,
            aiAnalysis: alert.aiAnalysis,
            location: alert.location,
            description: alert.description
          };
          io.to('security_dashboard').emit('report_update', reportPayload);
          io.emit('report_update', reportPayload);
        }
      } else {
        logger.error(`Python script exited with code ${code}`);

        // Graceful fallback
        alert.status = 'pending_review';
        await alert.save();
        io.emit('report_update', {
          alertId: alert.alertId,
          status: 'pending_review'
        });
      }
    });

    // Send input data to the Python process
    pythonProcess.stdin.write(inputData);
    pythonProcess.stdin.end();
  } catch (error) {
    logger.error('Error analyzing report:', error);

    // Graceful fallback
    alert.status = 'pending_review';
    await alert.save();
    io.emit('report_update', {
      alertId: alert.alertId,
      status: 'pending_review'
    });
  }
}

// Feedback loop function
function requestFeedback(alert) {
  logger.info(`🔄 Requesting feedback for report: ${alert.alertId}`);
  io.emit('feedback_request', {
    alertId: alert.alertId,
    message: 'Please provide feedback on this report.'
  });
}

// DEVELOPMENT ONLY: Disable JWT authentication for Socket.IO
// WARNING: Remove this in production!
io.use((socket, next) => {
  // Set a default user object for development to prevent crashes
  socket.user = {
    id: 'dev_user',
    role: 'security', // Change to 'security' for dashboard testing
    name: 'Dev User'
  };
  next();
});

io.on('connection', (socket) => {
  logger.info(`🔌 Client connected: ${socket.id} (User: ${socket.user.id})`);

  // Join rooms based on user role
  if (socket.user.role === 'student') {
    socket.join(`student_${socket.user.id}`);
  } else if (socket.user.role === 'security') {
    socket.join('security_dashboard');
  }

  // Emit updates to specific rooms
  socket.on('report_update', (data) => {
    if (socket.user.role === 'student') {
      io.to(`student_${socket.user.id}`).emit('report_update', data);
    } else if (socket.user.role === 'security') {
      io.to('security_dashboard').emit('report_update', data);
    }
  });

  // Added feedback_response socket event
  socket.on('feedback_response', async ({ alertId, confirmed }) => {
    try {
      // Save feedback to the database
      await Feedback.create({
        report_id: alertId,
        feedback: confirmed ? 'real' : 'fake',
        user_id: socket.user.id,
        timestamp: new Date()
      });

      // Update alert status
      const newStatus = confirmed ? 'real' : 'false_alarm';
      await Alert.updateOne(
        { alertId },
        { $set: { status: newStatus } }
      );

      // Notify relevant rooms
      if (socket.user.role === 'student') {
        io.to(`student_${socket.user.id}`).emit('report_update', { alertId, status: newStatus });
      } else if (socket.user.role === 'security') {
        io.to('security_dashboard').emit('report_update', { alertId, status: newStatus });
      }
    } catch (error) {
      logger.error('Error handling feedback_response:', error);
    }
  });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  logger.info(`🚀 Server running on http://localhost:${PORT}`);
});