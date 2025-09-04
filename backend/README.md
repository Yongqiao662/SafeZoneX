# SafeZoneX Backend Server

## 🚀 Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Start the Server
```bash
# Development mode (auto-restart on changes)
npm run dev

# Production mode
npm start
```

### 3. Test the Server
Open your browser and go to: http://localhost:8080

You should see:
```json
{
  "message": "SafeZoneX WebSocket Server",
  "status": "running",
  "activeAlerts": 0,
  "connectedClients": {
    "mobile": 0,
    "web": 0
  }
}
```

## 🔌 WebSocket Endpoints

### Connection URL
```
ws://localhost:8080
```

### Events

#### From Mobile App:
- `register` - Register as mobile client
- `sos_alert` - Send emergency alert
- `walking_partner_request` - Find walking partner
- `chat_message` - Send chat message

#### From Web Dashboard:
- `register` - Register as web client
- `acknowledge_alert` - Acknowledge emergency
- `resolve_alert` - Resolve emergency

#### Server Events:
- `sos_alert` - New emergency alert
- `alert_update` - Alert status changed
- `connection_update` - Client count updated

## 🧪 Testing

### Test SOS Alert
Send a WebSocket message:
```javascript
socket.emit('test_alert');
```

## 📝 Server Logs

The server will show:
- 🔌 Client connections
- 📱 Mobile registrations  
- 🖥️ Web registrations
- 🚨 SOS alerts received
- ✅ Alert acknowledgments
- ❌ Client disconnections
