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
const Friend = require('./models/Friend');
const Message = require('./models/Message');
const VerificationCode = require('./models/VerificationCode');

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

// Serve dashboard.html (classic version)
app.get('/dashboard.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// Serve enhanced dashboard (new features)
app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard_enhanced.html'));
});

app.get('/dashboard-enhanced.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard_enhanced.html'));
});

// Simple health/status endpoint used by mobile clients
app.get('/api/status', (req, res) => {
  return res.json({ success: true, message: 'SafeZoneX API server is running' });
});

// ML status endpoint (stub) - mobile expects this; returns basic info
app.get('/api/ml/status', (req, res) => {
  return res.json({ success: true, status: 'idle', message: 'ML subsystem not active on this deployment' });
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
    
  // Primary: send to security dashboard room
  io.to('security_dashboard').emit('report_update', reportPayload);
  // Fallback: also broadcast to all connected clients in case the dashboard
  // did not join the room (helps during debugging or when clients connect late)
  io.emit('report_update', reportPayload);
  console.log(`📢 Sent to dashboard room and broadcast - ${verificationTag} (${confidence}%), Priority: ${priority}`);

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
    console.log('📊 Dashboard fetching active reports');
    
    // Exclude resolved and false_alarm reports by default
    const reports = await Alert.find({
      status: { $nin: ['resolved', 'false_alarm'] }
    })
      .sort({ createdAt: -1 })
      .limit(100);

    console.log(`📋 Found ${reports.length} active reports for dashboard`);

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

// ==================== FRIENDS API ====================

// Get all friends for a user
app.get('/api/friends/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get accepted friendships
    const friendships = await Friend.find({ 
      userId: userId,
      status: 'accepted'
    }).sort({ lastInteraction: -1 });

    // Get friend details from User collection
    const friendIds = friendships.map(f => f.friendId);
    const friendUsers = await User.find({ userId: { $in: friendIds } });

    // Combine friendship data with user data
    const friendsList = friendships.map(friendship => {
      const friendUser = friendUsers.find(u => u.userId === friendship.friendId);
      if (!friendUser) return null;

      const lastSeenMinutes = Math.floor((Date.now() - new Date(friendUser.lastSeen)) / (1000 * 60));
      let lastSeenText = 'Online';
      if (lastSeenMinutes > 5) {
        if (lastSeenMinutes < 60) {
          lastSeenText = `${lastSeenMinutes} minutes ago`;
        } else if (lastSeenMinutes < 1440) {
          lastSeenText = `${Math.floor(lastSeenMinutes / 60)} hours ago`;
        } else {
          lastSeenText = `${Math.floor(lastSeenMinutes / 1440)} days ago`;
        }
      }

      return {
        id: friendUser.userId,
        name: friendUser.name,
        username: friendUser.email.split('@')[0],
        email: friendUser.email,
        isOnline: lastSeenMinutes <= 5,
        lastSeen: lastSeenText,
        profileColor: friendship.profileColor,
        location: friendUser.location?.latitude 
          ? `Last seen location` 
          : 'Location unavailable',
        locationUpdated: friendUser.location?.lastUpdated 
          ? new Date(friendUser.location.lastUpdated).toLocaleString()
          : 'N/A',
        profilePicture: friendUser.profilePicture
      };
    }).filter(f => f !== null);

    res.json({ success: true, friends: friendsList });
  } catch (error) {
    logger.error('❌ Error fetching friends:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch friends' });
  }
});

// Add a new friend
app.post('/api/friends/add', async (req, res) => {
  try {
    const { userId, friendEmail, profileColor } = req.body;

    // Find the friend user by email
    const friendUser = await User.findOne({ email: friendEmail });
    if (!friendUser) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Check if already friends
    const existingFriend = await Friend.findOne({ 
      userId: userId, 
      friendId: friendUser.userId 
    });

    if (existingFriend) {
      return res.status(400).json({ success: false, error: 'Already friends or request pending' });
    }

    // Create bidirectional friendship
    const friendship1 = new Friend({
      userId: userId,
      friendId: friendUser.userId,
      friendName: friendUser.name,
      friendEmail: friendUser.email,
      friendUsername: friendUser.email.split('@')[0],
      profileColor: profileColor || 'blue',
      status: 'accepted' // Auto-accept for now
    });

    const friendship2 = new Friend({
      userId: friendUser.userId,
      friendId: userId,
      friendName: req.body.userName || 'Friend',
      friendEmail: req.body.userEmail || '',
      friendUsername: req.body.userName?.toLowerCase().replace(/\s+/g, '_') || 'friend',
      profileColor: 'purple',
      status: 'accepted'
    });

    await friendship1.save();
    await friendship2.save();

    res.json({ 
      success: true, 
      message: 'Friend added successfully',
      friend: {
        id: friendUser.userId,
        name: friendUser.name,
        email: friendUser.email
      }
    });
  } catch (error) {
    logger.error('❌ Error adding friend:', error);
    res.status(500).json({ success: false, error: 'Failed to add friend' });
  }
});

// Check if user exists by email
app.get('/api/users/check', async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email is required' 
      });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    
    if (user) {
      logger.info(`✅ User exists: ${email}`);
      return res.json({ 
        success: true,
        exists: true, 
        user: {
          userId: user.userId,
          email: user.email,
          name: user.name,
          phone: user.phone,
          studentId: user.studentId,
          profilePicture: user.profilePicture
        }
      });
    } else {
      logger.info(`❌ User does not exist: ${email}`);
      return res.json({ 
        success: true,
        exists: false 
      });
    }
  } catch (error) {
    logger.error('❌ Error checking user existence:', error);
    res.status(500).json({ success: false, error: 'Failed to check user' });
  }
});

// Register a new user
app.post('/api/users/register', async (req, res) => {
  try {
    const { email, name, phone, studentId, profilePicture } = req.body;

    // Validate required fields
    if (!email || !name) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email and name are required' 
      });
    }

    // Check if user already exists by email OR studentId
    const existingUserByEmail = await User.findOne({ email: email.toLowerCase() });
    if (existingUserByEmail) {
      logger.info(`✅ User already exists: ${email}, returning existing user`);
      return res.json({ 
        success: true, 
        user: existingUserByEmail,
        message: 'User already exists' 
      });
    }

    // Check if studentId is already taken
    if (studentId) {
      const existingUserByStudentId = await User.findOne({ studentId: studentId });
      if (existingUserByStudentId) {
        logger.info(`✅ Student ID already exists: ${studentId}, returning existing user`);
        return res.json({ 
          success: true, 
          user: existingUserByStudentId,
          message: 'User already exists' 
        });
      }
    }

    // Generate unique userId
    const userId = uuidv4();

    // Create new user
    const newUser = new User({
      userId,
      email: email.toLowerCase(),
      name,
      phone: phone || '',
      studentId: studentId || userId,
      profilePicture: profilePicture || '',
      isVerified: true, // Auto-verify since we're using university email
      isActive: true,
      lastSeen: new Date()
    });

    await newUser.save();
    logger.info(`✅ New user registered: ${email}`);

    res.json({ 
      success: true, 
      user: newUser,
      message: 'Registration successful' 
    });
  } catch (error) {
    // Handle duplicate key errors specifically
    if (error.code === 11000) {
      logger.info(`⚠️ Duplicate key error, fetching existing user`);
      
      // Extract which field caused the duplicate
      const field = Object.keys(error.keyPattern)[0];
      const value = error.keyValue[field];
      
      // Find and return the existing user
      const existingUser = await User.findOne({ [field]: value });
      if (existingUser) {
        return res.json({ 
          success: true, 
          user: existingUser,
          message: 'User already exists' 
        });
      }
    }
    
    logger.error('❌ Error registering user:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to register user' 
    });
  }
});

// Search for users by email
app.get('/api/users/search', async (req, res) => {
  try {
    const { email, currentUserId } = req.query;

    if (!email) {
      return res.status(400).json({ success: false, error: 'Email query required' });
    }

    const users = await User.find({ 
      email: { $regex: email, $options: 'i' },
      userId: { $ne: currentUserId } // Exclude current user
    }).limit(10).select('userId name email profilePicture');

    res.json({ success: true, users });
  } catch (error) {
    logger.error('❌ Error searching users:', error);
    res.status(500).json({ success: false, error: 'Failed to search users' });
  }
});

// ==================== CHAT/MESSAGING API ====================

// Get chat messages between two users
app.get('/api/messages/:userId/:friendId', async (req, res) => {
  try {
    const { userId, friendId } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    const messages = await Message.find({
      $or: [
        { senderId: userId, recipientId: friendId },
        { senderId: friendId, recipientId: userId }
      ],
      deletedBy: { $ne: userId }
    })
    .sort({ timestamp: -1 })
    .limit(parseInt(limit))
    .skip(parseInt(offset));

    const formattedMessages = messages.reverse().map(msg => ({
      id: msg.messageId,
      message: msg.message,
      isMe: msg.senderId === userId,
      timestamp: msg.timestamp,
      isRead: msg.isRead,
      messageType: msg.messageType
    }));

    res.json({ success: true, messages: formattedMessages });
  } catch (error) {
    logger.error('❌ Error fetching messages:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch messages' });
  }
});

// Send a message
app.post('/api/messages/send', async (req, res) => {
  try {
    const { senderId, recipientId, message, senderName, messageType = 'text' } = req.body;

    if (!senderId || !recipientId || !message) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const newMessage = new Message({
      messageId: uuidv4(),
      senderId,
      recipientId,
      senderName,
      message,
      messageType,
      timestamp: new Date()
    });

    await newMessage.save();

    // Emit to specific recipient's room instead of broadcasting to all
    const recipientRoom = `user_${recipientId}`;
    io.to(recipientRoom).emit('new_message', {
      id: newMessage.messageId,
      senderId: senderId,
      recipientId: recipientId,
      senderName: senderName,
      message: message,
      timestamp: newMessage.timestamp,
      messageType: messageType
    });

    logger.info(`📤 Message sent from ${senderName} to user room: ${recipientRoom}`);

    res.json({ 
      success: true, 
      message: 'Message sent successfully',
      messageData: {
        id: newMessage.messageId,
        timestamp: newMessage.timestamp
      }
    });
  } catch (error) {
    logger.error('❌ Error sending message:', error);
    res.status(500).json({ success: false, error: 'Failed to send message' });
  }
});

// Mark messages as read
app.put('/api/messages/read', async (req, res) => {
  try {
    const { userId, friendId } = req.body;

    await Message.updateMany(
      { senderId: friendId, recipientId: userId, isRead: false },
      { isRead: true, readAt: new Date() }
    );

    res.json({ success: true, message: 'Messages marked as read' });
  } catch (error) {
    logger.error('❌ Error marking messages as read:', error);
    res.status(500).json({ success: false, error: 'Failed to mark messages as read' });
  }
});

// ==================== VERIFICATION CODE API ====================

// Send verification code
app.post('/api/verification/send', async (req, res) => {
  try {
    const { email, purpose = 'email_verification' } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, error: 'Email is required' });
    }

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Delete any existing codes for this email
    await VerificationCode.deleteMany({ email, purpose });

    // Create new verification code
    const verificationCode = new VerificationCode({
      email,
      code,
      purpose,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    });

    await verificationCode.save();

    // TODO: Send email with code (integrate SendGrid/Nodemailer)
    logger.info(`📧 Verification code for ${email}: ${code}`);

    // For development, return the code
    res.json({ 
      success: true, 
      message: 'Verification code sent successfully',
      // Remove this in production:
      code: process.env.NODE_ENV === 'development' ? code : undefined
    });
  } catch (error) {
    logger.error('❌ Error sending verification code:', error);
    res.status(500).json({ success: false, error: 'Failed to send verification code' });
  }
});

// Verify code
app.post('/api/verification/verify', async (req, res) => {
  try {
    const { email, code, purpose = 'email_verification' } = req.body;

    if (!email || !code) {
      return res.status(400).json({ success: false, error: 'Email and code are required' });
    }

    const verificationCode = await VerificationCode.findOne({ 
      email, 
      purpose,
      isUsed: false 
    });

    if (!verificationCode) {
      return res.status(404).json({ success: false, error: 'Verification code not found or expired' });
    }

    // Check if expired
    if (new Date() > verificationCode.expiresAt) {
      return res.status(400).json({ success: false, error: 'Verification code has expired' });
    }

    // Check attempts
    if (verificationCode.attempts >= verificationCode.maxAttempts) {
      return res.status(400).json({ success: false, error: 'Maximum verification attempts exceeded' });
    }

    // Verify code
    if (verificationCode.code !== code) {
      verificationCode.attempts += 1;
      await verificationCode.save();
      return res.status(400).json({ 
        success: false, 
        error: 'Invalid verification code',
        attemptsLeft: verificationCode.maxAttempts - verificationCode.attempts
      });
    }

    // Mark as used
    verificationCode.isUsed = true;
    verificationCode.usedAt = new Date();
    await verificationCode.save();

    res.json({ 
      success: true, 
      message: 'Verification successful'
    });
  } catch (error) {
    logger.error('❌ Error verifying code:', error);
    res.status(500).json({ success: false, error: 'Failed to verify code' });
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

  socket.on('join_room', async (data) => {
    const room = data.room || 'security_dashboard';
    socket.join(room);
    logger.info(`🔥 Client ${socket.id} joined room: ${room}`);

    // If a security dashboard joins, send the latest active reports
    // as an initial batch so the dashboard doesn't miss recent events.
    if (room === 'security_dashboard') {
      try {
        const reports = await Alert.find({
          status: { $nin: ['resolved', 'false_alarm'] }
        })
          .sort({ createdAt: -1 })
          .limit(100);

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

        socket.emit('initial_reports', {
          success: true,
          count: transformedReports.length,
          reports: transformedReports
        });

        logger.info(`📤 Sent ${transformedReports.length} initial reports to ${socket.id}`);
      } catch (err) {
        logger.error('❌ Failed to send initial reports to dashboard:', err);
      }
    }
  });

  // Handle user joining personal room for chat
  socket.on('join_user_room', async (data) => {
    const userId = data.userId;
    const roomName = `user_${userId}`;
    socket.join(roomName);
    socket.userId = userId; // Store user ID on socket for later use
    logger.info(`👤 User ${userId} joined personal room: ${roomName}`);
    
    // Update user's online status and last seen
    try {
      await User.findOneAndUpdate(
        { userId: userId },
        { 
          isOnline: true,
          lastSeen: new Date()
        }
      );
      logger.info(`✅ Updated online status for user: ${userId}`);
    } catch (error) {
      logger.error(`❌ Failed to update user status: ${error.message}`);
    }
  });

  // Handle user activity updates (for real-time status)
  socket.on('user_activity', async (data) => {
    const userId = data.userId;
    try {
      await User.findOneAndUpdate(
        { userId: userId },
        { 
          lastSeen: new Date(),
          isOnline: true
        }
      );
      logger.info(`⚡ Updated activity for user: ${userId}`);
    } catch (error) {
      logger.error(`❌ Failed to update user activity: ${error.message}`);
    }
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
  // Fallback: also broadcast the security event in case dashboard didn't join the room
  io.emit('security_sos_alert', sosAlert);
    
    logger.info(`📡 SOS broadcasted to all friends and security`);
  });

  // SOS Location Update - Real-time location sharing
  socket.on('sos_location_update', (data) => {
    logger.info(`📍 Location update from ${data.userId}`);
    
    // Broadcast location update to all friends
    const locationPayload = {
      ...data,
      socketId: socket.id,
      timestamp: new Date().toISOString()
    };

    // Existing broadcast used by friend clients
    io.emit('friend_location_update', locationPayload);

    // Also emit a standardized event name for dashboards and security clients
    io.to('security_dashboard').emit('sos_location_update', locationPayload);
    // Fallback broadcast in case dashboard isn't in the room
    io.emit('sos_location_update', locationPayload);
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

  socket.on('disconnect', async () => {
    logger.info(`🔌 Client disconnected: ${socket.id}`);
    
    // Update user's offline status if they were logged in
    if (socket.userId) {
      try {
        await User.findOneAndUpdate(
          { userId: socket.userId },
          { 
            isOnline: false,
            lastSeen: new Date()
          }
        );
        logger.info(`👋 Updated offline status for user: ${socket.userId}`);
      } catch (error) {
        logger.error(`❌ Failed to update user offline status: ${error.message}`);
      }
    }
  });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, "0.0.0.0", () => {
  logger.info(`🚀 Server running on port ${PORT}`);
  logger.info(`📊 Dashboard available at: /dashboard-enhanced.html`);
});
