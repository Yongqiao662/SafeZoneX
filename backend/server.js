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

// API to submit a report
app.post('/api/report', async (req, res) => {
  try {
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

    // Re-enable validation for userId, userName, and userPhone
    if (!userId || !userName || !userPhone) {
      return res.status(400).json({ error: 'Missing required user fields (userId, userName, userPhone)' });
    }
    if (!location || typeof location.latitude !== 'number' || typeof location.longitude !== 'number') {
      return res.status(400).json({ error: 'Missing or invalid location (latitude, longitude required)' });
    }

    const reportId = uuidv4();
    let initialConfidence = 50;
    if (description && description.length > 20) initialConfidence += 10;
    if (description && /theft|robbery|vandalism|harassment|drug/i.test(description)) initialConfidence += 10;
    if (evidenceImages && evidenceImages.length > 0) initialConfidence += 10;
    if (initialConfidence > 90) initialConfidence = 90;

    let status = 'pending';
    let aiAnalysis = null;

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
      alertType: alertType || 'emergency',
      priority: priority || 'high',
      status,
      createdAt: new Date()
    };

    // If confidence > 70%, skip AI analysis
    if (initialConfidence > 70) {
      status = 'real';
      aiAnalysis = {
        confidence: initialConfidence,
        details: 'High confidence (auto-classified as real)'
      };
      alertData.status = status;
      alertData.aiAnalysis = aiAnalysis;
      logger.info(`🚨 New report submitted: ${reportId} (auto-classified as real)`);
      const newAlert = new Alert(alertData);
      await newAlert.save();
      alertsCache.set(reportId, newAlert);
      res.json({ success: true, reportId });
      io.emit('report_update', {
        alertId: reportId,
        status,
        aiAnalysis
      });
    } else if (initialConfidence >= 50 && initialConfidence <= 70) {
      logger.info(`🚨 New report submitted: ${reportId} (pending AI analysis)`);
      const newAlert = new Alert(alertData);
      await newAlert.save();
      alertsCache.set(reportId, newAlert);
      res.json({ success: true, reportId });
      analyzeReport(newAlert);
    } else {
      status = 'pending_review';
      aiAnalysis = {
        confidence: initialConfidence,
        details: 'Low confidence, pending manual review'
      };
      alertData.status = status;
      alertData.aiAnalysis = aiAnalysis;
      logger.info(`🚨 New report submitted: ${reportId} (pending manual review)`);
      const newAlert = new Alert(alertData);
      await newAlert.save();
      alertsCache.set(reportId, newAlert);
      res.json({ success: true, reportId });
      io.emit('report_update', {
        alertId: reportId,
        status,
        aiAnalysis
      });
    }
  } catch (error) {
    logger.error('Error submitting report:', error && error.stack ? error.stack : error);
    res.status(500).json({ error: 'Failed to submit report' });
  }
});

// Signup or profile update endpoint
app.post('/api/user/signup', async (req, res) => {
  try {
    const {
      userId,
      email,
      name,
      phone,
      studentId,
      profilePicture,
      faceDescriptors,
      emergencyContacts,
      location,
      isVerified,
      verificationScore,
      safetyRating,
      totalWalks,
      isActive,
      joinedAt,
      lastSeen
    } = req.body;

    let user = await User.findOne({ email });
    if (user) {
      // Update profile if exists
      user.userId = userId || user.userId;
      user.name = name || user.name;
      user.phone = phone || user.phone;
      user.studentId = studentId || user.studentId;
      user.profilePicture = profilePicture || user.profilePicture;
      user.faceDescriptors = faceDescriptors || user.faceDescriptors;
      user.emergencyContacts = emergencyContacts || user.emergencyContacts;
      user.location = location || user.location;
      user.isVerified = isVerified !== undefined ? isVerified : user.isVerified;
      user.verificationScore = verificationScore !== undefined ? verificationScore : user.verificationScore;
      user.safetyRating = safetyRating !== undefined ? safetyRating : user.safetyRating;
      user.totalWalks = totalWalks !== undefined ? totalWalks : user.totalWalks;
      user.isActive = isActive !== undefined ? isActive : user.isActive;
      user.joinedAt = joinedAt || user.joinedAt;
      user.lastSeen = lastSeen || user.lastSeen;
      user.updatedAt = new Date();
      await user.save();
      return res.json({ success: true, user, message: 'Profile updated.' });
    }

    // Create new user
    user = new User({
      userId,
      email,
      name,
      phone,
      studentId,
      profilePicture,
      faceDescriptors,
      emergencyContacts,
      location,
      isVerified,
      verificationScore,
      safetyRating,
      totalWalks,
      isActive,
      joinedAt,
      lastSeen
    });
    await user.save();
    res.json({ success: true, user, message: 'User created.' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'User creation failed.', error: error.message });
  }
});

// Import required modules for AI analysis
const fs = require('fs');
const { spawn } = require('child_process');

// AI analysis function
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

        if (confidence > 70) {
          status = 'real';
          sendToDashboard = true;
          details = 'High confidence: classified as real';
        } else if (confidence >= 50 && confidence <= 70) {
          status = 'likely_real';
          sendToDashboard = true;
          details = `Confidence ${confidence}%: likely to be real`;
        } else {
          status = 'filtered';
          sendToDashboard = false;
          details = 'Low confidence: filtered out';
        }

        alert.status = status;
        alert.aiAnalysis = {
          confidence,
          details
        };
        await alert.save();

        logger.info(`✅ Report analysis complete: ${alert.alertId} (${status})`);

        // Only send to dashboard if confidence >= 50%
        if (sendToDashboard) {
          io.emit('report_update', {
            alertId: alert.alertId,
            status,
            aiAnalysis: alert.aiAnalysis
          });
        }

        // Feedback loop for likely_real
        if (status === 'likely_real') {
          requestFeedback(alert);
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

// Implemented Socket.IO authentication
// DEVELOPMENT ONLY: Disable JWT authentication for Socket.IO
// WARNING: Remove this in production!
io.use((socket, next) => {
  // Allow all connections without authentication
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


