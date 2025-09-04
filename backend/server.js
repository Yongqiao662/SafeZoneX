const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const server = http.createServer(app);

// Configure CORS for Socket.IO
const io = socketIo(server, {
  cors: {
    origin: "*", // In production, specify your domain
    methods: ["GET", "POST"],
    credentials: true
  }
});

app.use(cors());
app.use(express.json());

// Store active alerts in memory (in production, use a database)
let activeAlerts = [];
let connectedClients = {
  mobile: [],
  web: []
};

// Basic HTTP endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'SafeZoneX WebSocket Server',
    status: 'running',
    activeAlerts: activeAlerts.length,
    connectedClients: {
      mobile: connectedClients.mobile.length,
      web: connectedClients.web.length
    }
  });
});

// Get all active alerts
app.get('/alerts', (req, res) => {
  res.json(activeAlerts);
});

// WebSocket connection handling
io.on('connection', (socket) => {
  console.log(`🔌 Client connected: ${socket.id}`);
  
  // Handle client type registration
  socket.on('register', (data) => {
    const clientType = data.type; // 'mobile' or 'web'
    socket.clientType = clientType;
    
    if (clientType === 'mobile') {
      connectedClients.mobile.push(socket.id);
      console.log(`📱 Mobile client registered: ${socket.id}`);
    } else if (clientType === 'web') {
      connectedClients.web.push(socket.id);
      console.log(`🖥️ Web client registered: ${socket.id}`);
      
      // Send existing alerts to newly connected web client
      socket.emit('existing_alerts', activeAlerts);
    }
    
    // Broadcast updated connection count
    io.emit('connection_update', {
      mobile: connectedClients.mobile.length,
      web: connectedClients.web.length
    });
  });
  
  // Handle SOS alerts from mobile app
  socket.on('sos_alert', (alertData) => {
    console.log('🚨 SOS ALERT RECEIVED:', alertData);
    
    // Add server timestamp and unique ID
    const alert = {
      ...alertData,
      id: alertData.id || uuidv4(),
      serverTimestamp: new Date().toIso8601String(),
      status: 'active'
    };
    
    // Store alert
    activeAlerts.unshift(alert);
    
    // Broadcast to all web dashboards
    io.emit('sos_alert', {
      type: 'sos_alert',
      payload: alert
    });
    
    console.log(`📡 Alert broadcasted to ${connectedClients.web.length} web clients`);
  });
  
  // Handle alert acknowledgment from web dashboard
  socket.on('acknowledge_alert', (data) => {
    console.log('✅ Alert acknowledged:', data.alertId);
    
    // Update alert status
    const alertIndex = activeAlerts.findIndex(alert => alert.id === data.alertId);
    if (alertIndex !== -1) {
      activeAlerts[alertIndex].status = 'acknowledged';
      activeAlerts[alertIndex].acknowledgedAt = new Date().toISOString();
      activeAlerts[alertIndex].acknowledgedBy = data.acknowledgedBy || 'Security Team';
    }
    
    // Broadcast update to all clients
    io.emit('alert_update', {
      type: 'acknowledge_alert',
      alertId: data.alertId,
      status: 'acknowledged',
      timestamp: new Date().toISOString()
    });
  });
  
  // Handle alert resolution from web dashboard
  socket.on('resolve_alert', (data) => {
    console.log('✅ Alert resolved:', data.alertId);
    
    // Update alert status
    const alertIndex = activeAlerts.findIndex(alert => alert.id === data.alertId);
    if (alertIndex !== -1) {
      activeAlerts[alertIndex].status = 'resolved';
      activeAlerts[alertIndex].resolvedAt = new Date().toISOString();
      activeAlerts[alertIndex].resolvedBy = data.resolvedBy || 'Security Team';
    }
    
    // Broadcast update to all clients
    io.emit('alert_update', {
      type: 'resolve_alert',
      alertId: data.alertId,
      status: 'resolved',
      timestamp: new Date().toISOString()
    });
  });
  
  // Handle test alerts (for development)
  socket.on('test_alert', () => {
    console.log('🧪 Test alert triggered');
    
    const testAlert = {
      id: uuidv4(),
      userId: 'test_user_' + Date.now(),
      userName: 'Test User',
      userPhone: '+1234567890',
      latitude: 37.7749 + (Math.random() - 0.5) * 0.01,
      longitude: -122.4194 + (Math.random() - 0.5) * 0.01,
      address: 'Test Campus Location',
      timestamp: new Date().toISOString(),
      alertType: 'Test Emergency',
      status: 'active',
      additionalInfo: 'This is a test alert from the server',
      serverTimestamp: new Date().toISOString()
    };
    
    activeAlerts.unshift(testAlert);
    
    io.emit('sos_alert', {
      type: 'sos_alert',
      payload: testAlert
    });
  });
  
  // Handle walking partner requests
  socket.on('walking_partner_request', (data) => {
    console.log('👥 Walking partner request:', data);
    
    // Broadcast to other mobile clients in the area
    socket.broadcast.emit('partner_request_notification', data);
  });
  
  // Handle chat messages
  socket.on('chat_message', (data) => {
    console.log('💬 Chat message:', data);
    
    // Broadcast to web dashboards (security/support)
    io.emit('chat_message', {
      ...data,
      timestamp: new Date().toISOString()
    });
  });
  
  // Handle disconnection
  socket.on('disconnect', () => {
    console.log(`❌ Client disconnected: ${socket.id}`);
    
    // Remove from connected clients
    if (socket.clientType === 'mobile') {
      connectedClients.mobile = connectedClients.mobile.filter(id => id !== socket.id);
    } else if (socket.clientType === 'web') {
      connectedClients.web = connectedClients.web.filter(id => id !== socket.id);
    }
    
    // Broadcast updated connection count
    io.emit('connection_update', {
      mobile: connectedClients.mobile.length,
      web: connectedClients.web.length
    });
  });
  
  // Send connection confirmation
  socket.emit('connected', {
    message: 'Connected to SafeZoneX server',
    clientId: socket.id,
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 8080;

server.listen(PORT, () => {
  console.log('\n🚀 SafeZoneX WebSocket Server Started');
  console.log(`📡 Server running on http://localhost:${PORT}`);
  console.log(`🔌 WebSocket endpoint: ws://localhost:${PORT}`);
  console.log('🛡️ Ready to handle emergency alerts...\n');
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down server...');
  server.close(() => {
    console.log('✅ Server shut down gracefully');
    process.exit(0);
  });
});
