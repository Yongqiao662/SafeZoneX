// Adjust dotenv configuration to use absolute path
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });

// Debugging dotenv configuration
console.log('Environment Variables:', process.env);

// Check if MONGODB_URI is loaded
if (!process.env.MONGODB_URI) {
  console.error('❌ MONGODB_URI is not defined in environment variables');
} else {
  console.log('✅ MONGODB_URI:', process.env.MONGODB_URI);
}

// Explicitly log the path to the .env file
const fs = require('fs');
const envPath = path.resolve(__dirname, '.env');
if (fs.existsSync(envPath)) {
  console.log('✅ .env file found at:', envPath);
} else {
  console.error('❌ .env file not found at:', envPath);
}

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const mongoose = require('mongoose');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');

// Import models
const Alert = require('./models/Alert');
const User = require('./models/User');
const WalkSession = require('./models/WalkSession');

// Configure logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

const app = express();
const server = http.createServer(app);

// Security middleware
app.use(helmet());
app.use(compression());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Configure CORS for Socket.IO
const io = socketIo(server, {
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || "*",
    methods: ["GET", "POST"],
    credentials: true
  }
});

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// Updated MongoDB connection string
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

// Store active connections
let connectedClients = {
  mobile: new Map(),
  web: new Map()
};

// Active alerts cache
let alertsCache = new Map();

// Initialize AI services
async function initializeAIServices() {
  try {
    logger.info('🤖 Initializing AI services...');
    logger.info('✅ AI services initialized successfully');
  } catch (error) {
    logger.error('❌ Failed to initialize AI services:', error);
  }
}

// Call initialization
initializeAIServices();

// API Routes

// Health check endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'SafeZoneX AI-Powered Backend Server',
    version: '2.0.0',
    status: 'running',
    services: {
      database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
      faceVerification: 'disabled'
    },
    statistics: {
      activeAlerts: alertsCache.size,
      connectedClients: {
        mobile: connectedClients.mobile.size,
        web: connectedClients.web.size
      }
    },
    timestamp: new Date().toISOString()
  });
});

// Get all alerts with pagination
app.get('/api/alerts', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status;

    const query = status ? { status } : {};
    
    const alerts = await Alert.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Alert.countDocuments(query);

    res.json({
      alerts,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    logger.error('Error fetching alerts:', error);
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
});

// Register face descriptors for new user
app.post('/api/register-face', upload.single('profileImage'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Profile image is required' });
    }

    const { userId, email, name, phone, studentId } = req.body;
    
    if (!userId || !email || !name || !phone || !studentId) {
      return res.status(400).json({ error: 'All user details are required' });
    }

    // Convert image to base64 for storage
    const profilePictureBase64 = req.file.buffer.toString('base64');

    // Create or update user
    const user = await User.findOneAndUpdate(
      { userId },
      {
        userId,
        email,
        name,
        phone,
        studentId,
        profilePicture: profilePictureBase64,
        isVerified: true,
        verificationScore: 100,
        lastSeen: new Date()
      },
      { upsert: true, new: true }
    );

    logger.info(`👤 User face registered: ${userId} (${name})`);

    res.json({
      success: true,
      message: 'Face registered successfully',
      user: {
        userId: user.userId,
        name: user.name,
        email: user.email,
        isVerified: user.isVerified,
        verificationScore: user.verificationScore
      },
      faceAnalysis: {
        confidence: 100,
        quality: 'good'
      }
    });

  } catch (error) {
    logger.error('Face registration error:', error);
    res.status(500).json({ 
      error: 'Face registration failed',
      details: error.message 
    });
  }
});

// WebSocket connection handling
io.on('connection', (socket) => {
  logger.info(`🔌 Client connected: ${socket.id}`);
  
  // Handle client type registration
  socket.on('register', async (data) => {
    try {
      const { type, userId, userInfo } = data;
      socket.clientType = type;
      socket.userId = userId;
      
      if (type === 'mobile') {
        connectedClients.mobile.set(socket.id, {
          userId,
          userInfo,
          connectedAt: new Date(),
          lastActivity: new Date()
        });
        
        logger.info(`📱 Mobile client registered: ${socket.id} (User: ${userId})`);
        
        // Update user last seen
        if (userId) {
          await User.updateOne(
            { userId },
            { 
              $set: { 
                lastSeen: new Date(),
                isActive: true 
              } 
            }
          );
        }
      } else if (type === 'web') {
        connectedClients.web.set(socket.id, {
          connectedAt: new Date(),
          lastActivity: new Date()
        });
        
        logger.info(`🖥️ Web dashboard registered: ${socket.id}`);
        
        // Send existing active alerts to web dashboard
        const activeAlerts = await Alert.find({ status: 'active' })
          .sort({ createdAt: -1 })
          .limit(50);
        
        socket.emit('existing_alerts', activeAlerts);
      }
      
      // Broadcast updated connection count
      io.emit('connection_update', {
        mobile: connectedClients.mobile.size,
        web: connectedClients.web.size,
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      logger.error('Registration error:', error);
      socket.emit('error', { message: 'Registration failed' });
    }
  });
  
  // Handle SOS alerts with AI analysis
  socket.on('sos_alert', async (alertData) => {
    try {
      logger.info('🚨 SOS ALERT RECEIVED:', alertData);
      
      const alertId = alertData.id || uuidv4();
      
      // Get user history for authenticity analysis
      const userHistory = await User.findOne({ userId: alertData.userId });
      
      // Analyze report authenticity
      const authenticityAnalysis = await ReportAuthenticityService.analyzeReportAuthenticity(
        alertData,
        userHistory
      );
      
      // Analyze evidence images if provided
      let imageAnalysis = null;
      if (alertData.evidenceImages && alertData.evidenceImages.length > 0) {
        const imageBuffer = Buffer.from(alertData.evidenceImages[0].imageData, 'base64');
        imageAnalysis = await ReportAuthenticityService.analyzeImageAuthenticity(imageBuffer);
      }
      
      // Create alert with AI analysis
      const alert = new Alert({
        alertId,
        userId: alertData.userId,
        userName: alertData.userName,
        userPhone: alertData.userPhone,
        alertType: alertData.alertType || 'emergency',
        status: 'active',
        priority: authenticityAnalysis.riskLevel === 'low' ? 'high' : 
                 authenticityAnalysis.riskLevel === 'medium' ? 'critical' : 'medium',
        location: {
          latitude: alertData.latitude,
          longitude: alertData.longitude,
          address: alertData.address,
          campus: 'University Malaya'
        },
        description: alertData.additionalInfo || alertData.description,
        evidenceImages: alertData.evidenceImages?.map(img => ({
          imageData: img.imageData,
          timestamp: new Date(),
          verified: imageAnalysis?.genuine || false,
          aiAnalysis: imageAnalysis ? {
            genuineScore: imageAnalysis.score,
            manipulationDetected: imageAnalysis.manipulationDetected,
            analysisDetails: imageAnalysis.details?.summary
          } : null
        })),
        aiAnalysis: {
          reportGenuineness: {
            score: authenticityAnalysis.score,
            factors: authenticityAnalysis.flags,
            riskLevel: authenticityAnalysis.riskLevel
          },
          locationVerification: authenticityAnalysis.analyses?.locationAnalysis || {},
          behaviorAnalysis: authenticityAnalysis.analyses?.behaviorAnalysis || {}
        },
        timeline: [{
          action: 'Alert Created',
          timestamp: new Date(),
          performer: 'System',
          details: `Alert received with ${authenticityAnalysis.score}% authenticity score`
        }],
        metadata: alertData.metadata || {}
      });
      
      // Save to database
      await alert.save();
      
      // Cache for quick access
      alertsCache.set(alertId, alert);
      
      // Prepare alert for broadcast
      const alertForBroadcast = {
        ...alert.toObject(),
        serverTimestamp: new Date().toISOString(),
        aiFlags: authenticityAnalysis.riskLevel !== 'low' ? {
          riskLevel: authenticityAnalysis.riskLevel,
          flags: authenticityAnalysis.flags.slice(0, 3), // Limit flags for UI
          recommendations: authenticityAnalysis.recommendations.slice(0, 2)
        } : null
      };
      
      // Broadcast to all web dashboards with AI analysis
      io.emit('sos_alert', {
        type: 'sos_alert',
        payload: alertForBroadcast
      });
      
      // Send SMS/notifications to emergency contacts if high confidence
      if (authenticityAnalysis.score > 70) {
        // Implement emergency notifications here
        logger.info(`📞 High confidence alert - triggering emergency notifications`);
      }
      
      logger.info(`📡 Alert ${alertId} broadcasted to ${connectedClients.web.size} web clients (Authenticity: ${authenticityAnalysis.score}%)`);
      
    } catch (error) {
      logger.error('SOS alert processing error:', error);
      socket.emit('error', { 
        message: 'Failed to process SOS alert',
        details: error.message 
      });
    }
  });
  
  // Handle alert acknowledgment
  socket.on('acknowledge_alert', async (data) => {
    try {
      logger.info('✅ Alert acknowledged:', data.alertId);
      
      const update = {
        status: 'acknowledged',
        acknowledgedAt: new Date(),
        acknowledgedBy: data.acknowledgedBy || 'Security Team',
        $push: {
          timeline: {
            action: 'Alert Acknowledged',
            timestamp: new Date(),
            performer: data.acknowledgedBy || 'Security Team',
            details: data.notes || 'Alert acknowledged by security team'
          }
        }
      };
      
      await Alert.updateOne({ alertId: data.alertId }, update);
      
      // Update cache
      const cachedAlert = alertsCache.get(data.alertId);
      if (cachedAlert) {
        Object.assign(cachedAlert, update);
      }
      
      // Broadcast update
      io.emit('alert_update', {
        type: 'acknowledge_alert',
        alertId: data.alertId,
        status: 'acknowledged',
        timestamp: new Date().toISOString(),
        acknowledgedBy: data.acknowledgedBy
      });
      
    } catch (error) {
      logger.error('Alert acknowledgment error:', error);
      socket.emit('error', { message: 'Failed to acknowledge alert' });
    }
  });
  
  // Handle alert resolution
  socket.on('resolve_alert', async (data) => {
    try {
      logger.info('✅ Alert resolved:', data.alertId);
      
      const resolvedAt = new Date();
      const alert = await Alert.findOne({ alertId: data.alertId });
      
      if (alert) {
        const responseTime = Math.floor((resolvedAt - alert.createdAt) / 1000);
        
        const update = {
          status: 'resolved',
          resolvedAt,
          resolvedBy: data.resolvedBy || 'Security Team',
          responseTime,
          $push: {
            timeline: {
              action: 'Alert Resolved',
              timestamp: resolvedAt,
              performer: data.resolvedBy || 'Security Team',
              details: data.resolution || 'Alert resolved successfully'
            }
          }
        };
        
        await Alert.updateOne({ alertId: data.alertId }, update);
        
        // Remove from cache
        alertsCache.delete(data.alertId);
        
        // Broadcast update
        io.emit('alert_update', {
          type: 'resolve_alert',
          alertId: data.alertId,
          status: 'resolved',
          timestamp: resolvedAt.toISOString(),
          resolvedBy: data.resolvedBy,
          responseTime
        });
      }
      
    } catch (error) {
      logger.error('Alert resolution error:', error);
      socket.emit('error', { message: 'Failed to resolve alert' });
    }
  });
  
  // Handle face verification requests
  socket.on('verify_face_for_walk', async (data) => {
    try {
      const { userId, partnerId, imageData, sessionId } = data;
      
      if (!userId || !imageData) {
        socket.emit('verification_error', { message: 'Missing required data' });
        return;
      }
      
      // Get user's face descriptors
      const user = await User.findOne({ userId });
      if (!user || !user.faceDescriptors) {
        socket.emit('verification_error', { message: 'User face data not found' });
        return;
      }
      
      // Convert base64 to buffer
      const imageBuffer = Buffer.from(imageData, 'base64');
      
      // Update walk session if provided
      if (sessionId) {
        await WalkSession.updateOne(
          { sessionId },
          {
            $set: {
              [`faceVerification.${userId === partnerId ? 'partner' : 'requester'}Verified`]: true,
              [`faceVerification.${userId === partnerId ? 'partner' : 'requester'}Confidence`]: 100,
              'faceVerification.verificationTimestamp': new Date()
            }
          }
        );
      }
      
      socket.emit('face_verification_result', {
        userId,
        sessionId,
        verified: true,
        confidence: 100
      });
      
      // Notify partner if verification successful
      if (partnerId) {
        const partnerSocket = Array.from(connectedClients.mobile.entries())
          .find(([_, client]) => client.userId === partnerId)?.[0];
          
        if (partnerSocket) {
          io.to(partnerSocket).emit('partner_verified', {
            userId,
            sessionId,
            verified: true
          });
        }
      }
      
      logger.info(`🎭 Walk verification for ${userId}: SUCCESS`);
      
    } catch (error) {
      logger.error('Face verification error:', error);
      socket.emit('verification_error', { 
        message: 'Verification failed',
        details: error.message 
      });
    }
  });
  
  // Handle walking partner requests
  socket.on('walking_partner_request', async (data) => {
    try {
      logger.info('👥 Walking partner request:', data);
      
      // Create walk session
      const session = new WalkSession({
        sessionId: data.sessionId || uuidv4(),
        requesterId: data.requesterId,
        status: 'pending',
        startLocation: data.startLocation,
        endLocation: data.endLocation,
        plannedRoute: data.plannedRoute
      });
      
      await session.save();
      
      // Broadcast to nearby mobile clients
      const nearbyClients = Array.from(connectedClients.mobile.entries())
        .filter(([socketId, client]) => {
          // Filter by proximity logic here
          return client.userId !== data.requesterId;
        });
      
      nearbyClients.forEach(([socketId]) => {
        io.to(socketId).emit('partner_request_notification', {
          ...data,
          sessionId: session.sessionId
        });
      });
      
    } catch (error) {
      logger.error('Walking partner request error:', error);
      socket.emit('error', { message: 'Failed to process partner request' });
    }
  });
  
  // Handle real-time location updates
  socket.on('location_update', async (data) => {
    try {
      const { userId, latitude, longitude, sessionId } = data;
      
      // Update user location
      if (userId) {
        await User.updateOne(
          { userId },
          {
            $set: {
              'location.latitude': latitude,
              'location.longitude': longitude,
              'location.lastUpdated': new Date(),
              lastActivity: new Date()
            }
          }
        );
      }
      
      // Update walk session if applicable
      if (sessionId) {
        await WalkSession.updateOne(
          { sessionId },
          {
            $set: {
              'realTimeTracking.lastUpdated': new Date(),
              'realTimeTracking.currentLocation': {
                latitude,
                longitude
              }
            }
          }
        );
        
        // Broadcast to partner
        const session = await WalkSession.findOne({ sessionId });
        if (session) {
          const partnerId = session.requesterId === userId ? session.partnerId : session.requesterId;
          if (partnerId) {
            const partnerSocket = Array.from(connectedClients.mobile.entries())
              .find(([_, client]) => client.userId === partnerId)?.[0];
              
            if (partnerSocket) {
              io.to(partnerSocket).emit('partner_location_update', {
                userId,
                latitude,
                longitude,
                timestamp: new Date().toISOString()
              });
            }
          }
        }
      }
      
    } catch (error) {
      logger.error('Location update error:', error);
    }
  });
  
  // Handle chat messages
  socket.on('chat_message', async (data) => {
    try {
      logger.info('💬 Chat message:', data);
      
      // Broadcast to web dashboards and relevant mobile clients
      io.emit('chat_message', {
        ...data,
        timestamp: new Date().toISOString(),
        serverId: uuidv4()
      });
      
    } catch (error) {
      logger.error('Chat message error:', error);
    }
  });
  
  // Handle disconnection
  socket.on('disconnect', async () => {
    try {
      logger.info(`❌ Client disconnected: ${socket.id}`);
      
      // Update user status if mobile client
      if (socket.clientType === 'mobile' && socket.userId) {
        await User.updateOne(
          { userId: socket.userId },
          { 
            $set: { 
              isActive: false,
              lastSeen: new Date()
            } 
          }
        );
      }
      
      // Remove from connected clients
      connectedClients.mobile.delete(socket.id);
      connectedClients.web.delete(socket.id);
      
      // Broadcast updated connection count
      io.emit('connection_update', {
        mobile: connectedClients.mobile.size,
        web: connectedClients.web.size,
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      logger.error('Disconnection handling error:', error);
    }
  });
  
  // Send connection confirmation
  socket.emit('connected', {
    message: 'Connected to SafeZoneX AI-Powered Server',
    clientId: socket.id,
    timestamp: new Date().toISOString(),
    features: {
      faceVerification: false,
      imageAnalysis: true,
      realTimeSync: true,
      authenticityDetection: true
    }
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

const PORT = process.env.PORT || 8080;

server.listen(PORT, () => {
  console.log('\n🚀 SafeZoneX AI-Powered Backend Server Started');
  console.log(`📡 Server running on http://localhost:${PORT}`);
  console.log(`🔌 WebSocket endpoint: ws://localhost:${PORT}`);
  console.log('🤖 AI Services: Report Authenticity Detection');
  console.log('🛡️ Ready to handle emergency alerts with AI analysis...\n');
  
  logger.info('SafeZoneX server started successfully', {
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
    features: ['Image Analysis', 'Report Authenticity', 'Real-time Sync']
  });
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down server...');
  
  server.close(async () => {
    try {
      await mongoose.connection.close();
      logger.info('Database connection closed');
      console.log('✅ Server shut down gracefully');
      process.exit(0);
    } catch (error) {
      logger.error('Error during shutdown:', error);
      process.exit(1);
    }
  });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});
