# SafeZoneX Real-Time Emergency Monitoring

This web dashboard provides real-time monitoring of SOS alerts from the SafeZoneX mobile app.

## Features

### 🚨 Real-Time Alert Monitoring
- Live SOS alerts from mobile app users
- Browser notifications for immediate attention
- Color-coded alert status (Active, Acknowledged, Resolved)

### 📊 Dashboard Overview
- Statistics: Active, Acknowledged, and Resolved alerts
- Real-time connection status indicator
- Alert history with timestamps

### 🎯 Alert Management
- **Acknowledge**: Mark alert as received and being handled
- **Resolve**: Mark alert as completely handled
- **View Map**: See exact location of the emergency

### 🔔 Browser Notifications
- Pop-up notifications even when tab is not active
- Auto-close after 10 seconds
- Click notification to focus on dashboard

## Setup Instructions

### 1. Run the Web Dashboard

```bash
cd frontend/web
flutter pub get
flutter run -d chrome
```

### 2. WebSocket Server Setup

The dashboard expects a WebSocket server at `ws://localhost:8080/ws`. You'll need to set up a WebSocket server that:

1. Accepts connections from both mobile app and web dashboard
2. Forwards SOS alerts from mobile to web in real-time
3. Handles acknowledgment and resolution updates

### Example WebSocket Message Format

**SOS Alert from Mobile:**
```json
{
  "type": "sos_alert",
  "payload": {
    "id": "alert_123",
    "userId": "user_456",
    "userName": "John Smith",
    "userPhone": "+1234567890",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "address": "Campus Library, University Ave",
    "timestamp": "2025-09-05T14:30:00Z",
    "alertType": "Emergency",
    "status": "active",
    "additionalInfo": "Suspicious person following me"
  }
}
```

**Acknowledgment from Web:**
```json
{
  "type": "acknowledge_alert",
  "alertId": "alert_123",
  "timestamp": "2025-09-05T14:32:00Z"
}
```

**Resolution from Web:**
```json
{
  "type": "resolve_alert",
  "alertId": "alert_123",
  "timestamp": "2025-09-05T14:35:00Z"
}
```

## Mobile App Integration

### Sending SOS Alerts

In your mobile app's SOS screen, add WebSocket functionality:

```dart
// In home_screen.dart - Guardian Pulse / SOS button
void _triggerSOS() async {
  final alert = Alert(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    type: 'Emergency',
    timestamp: DateTime.now(),
    location: currentAddress,
    userId: currentUserId,
    userName: currentUserName,
    userPhone: currentUserPhone,
    latitude: currentLatitude,
    longitude: currentLongitude,
    status: 'active',
    additionalInfo: 'SOS button pressed',
  );
  
  // Send to WebSocket server
  websocketService.sendAlert(alert);
  
  // Navigate to SOS Active Screen
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => SOSActiveScreen(),
  ));
}
```

## Server Technologies

### Recommended Backend Stack:
- **Node.js + Socket.io**: Easy WebSocket implementation
- **Python + WebSockets**: Simple and scalable
- **Go + Gorilla WebSocket**: High performance
- **Firebase Realtime Database**: Managed solution

### Example Node.js Server:
```javascript
const io = require('socket.io')(8080, {
  cors: { origin: "*" }
});

io.on('connection', (socket) => {
  console.log('Client connected');
  
  socket.on('sos_alert', (data) => {
    // Broadcast to all web dashboards
    socket.broadcast.emit('sos_alert', data);
  });
  
  socket.on('acknowledge_alert', (data) => {
    // Update alert status
    socket.broadcast.emit('alert_update', data);
  });
});
```

## Testing

1. **Mock Data**: The dashboard includes mock alerts for testing
2. **Test Button**: FAB button adds test alerts
3. **Browser Notifications**: Test browser notification permissions

## Browser Support

- Chrome ✅
- Firefox ✅  
- Safari ✅
- Edge ✅

## Security Considerations

- Use WSS (secure WebSocket) in production
- Implement authentication for web dashboard
- Encrypt sensitive user data
- Rate limiting on WebSocket connections
- CORS configuration for web security

## Future Enhancements

- Google Maps integration for location visualization
- Audio alerts for critical emergencies
- Multi-campus support
- Alert escalation policies
- Integration with campus security systems
- Mobile push notifications to security team
