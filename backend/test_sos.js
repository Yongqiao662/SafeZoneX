// Test script to simulate SOS alert
const io = require('socket.io-client');

console.log('🧪 Starting SOS Test Script...\n');

// Connect to backend
const socket = io('http://localhost:8080', {
  transports: ['websocket'],
});

socket.on('connect', () => {
  console.log('✅ Connected to backend server');
  console.log('📡 Sending test SOS alert in 2 seconds...\n');
  
  setTimeout(() => {
    const testSOS = {
      id: 'test_' + Date.now(),
      userId: 'test_user_123',
      userName: 'Demo User',
      userPhoto: '',
      latitude: 3.1225,
      longitude: 101.6532,
      address: 'University Malaya Campus - Main Building',
      timestamp: new Date().toISOString(),
      message: '🆘 Emergency! I need help. Please check on me.',
      urgency: 'high',
      status: 'active',
      acknowledgedBy: [],
    };

    console.log('📤 Sending SOS Alert:');
    console.log(JSON.stringify(testSOS, null, 2));
    console.log('');
    
    socket.emit('sos_alert', testSOS);
    console.log('✅ SOS alert sent!');
    console.log('👉 Check your Flutter app Friends screen now!');
    console.log('   You should see a popup notification\n');
    
    // Send location update after 5 seconds
    setTimeout(() => {
      const locationUpdate = {
        userId: 'test_user_123',
        latitude: 3.1226,
        longitude: 101.6533,
        address: 'University Malaya Campus - Moving towards Library',
        timestamp: new Date().toISOString(),
        status: 'moving',
      };
      
      console.log('📍 Sending location update:');
      console.log(JSON.stringify(locationUpdate, null, 2));
      socket.emit('sos_location_update', locationUpdate);
      console.log('✅ Location update sent!\n');
    }, 5000);
    
    // End SOS after 15 seconds
    setTimeout(() => {
      const sosEnd = {
        userId: 'test_user_123',
        timestamp: new Date().toISOString(),
        message: 'SOS has been deactivated',
      };
      
      console.log('🛑 Ending SOS:');
      console.log(JSON.stringify(sosEnd, null, 2));
      socket.emit('sos_ended', sosEnd);
      console.log('✅ SOS ended!\n');
      
      setTimeout(() => {
        console.log('🏁 Test completed. Disconnecting...');
        socket.disconnect();
        process.exit(0);
      }, 2000);
    }, 15000);
    
  }, 2000);
});

socket.on('friend_sos_alert', (data) => {
  console.log('🔔 Received broadcast confirmation:', data);
});

socket.on('disconnect', () => {
  console.log('❌ Disconnected from server');
});

socket.on('error', (error) => {
  console.error('❌ Error:', error);
});

console.log('⏳ Connecting to backend server at http://localhost:8080...');
