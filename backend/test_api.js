#!/usr/bin/env node

/**
 * API Test Script
 * Tests all new API endpoints created for Friends, Chat, and Verification
 */

const http = require('http');

const BASE_URL = 'localhost';
const PORT = 8080;

// Helper function to make HTTP requests
function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: BASE_URL,
      port: PORT,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve({
            statusCode: res.statusCode,
            body: JSON.parse(body),
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            body: body,
          });
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

// Test functions
async function testFriendsAPI() {
  console.log('\n=== Testing Friends API ===\n');

  try {
    // Test 1: Get friends (should return empty or existing friends)
    console.log('1. Testing GET /api/friends/:userId');
    const getFriendsResult = await makeRequest('GET', '/api/friends/test_user_1');
    console.log('Status:', getFriendsResult.statusCode);
    console.log('Response:', JSON.stringify(getFriendsResult.body, null, 2));

    // Test 2: Add friend
    console.log('\n2. Testing POST /api/friends/add');
    const addFriendResult = await makeRequest('POST', '/api/friends/add', {
      userId: 'test_user_1',
      friendEmail: 'friend@example.com',
      userName: 'Test User',
      userEmail: 'testuser@example.com',
      profileColor: 'blue',
    });
    console.log('Status:', addFriendResult.statusCode);
    console.log('Response:', JSON.stringify(addFriendResult.body, null, 2));

    // Test 3: Search users
    console.log('\n3. Testing GET /api/users/search');
    const searchResult = await makeRequest('GET', '/api/users/search?email=test&currentUserId=test_user_1');
    console.log('Status:', searchResult.statusCode);
    console.log('Response:', JSON.stringify(searchResult.body, null, 2));

    console.log('\n✅ Friends API tests completed');
  } catch (error) {
    console.error('❌ Friends API test failed:', error.message);
  }
}

async function testChatAPI() {
  console.log('\n=== Testing Chat/Messaging API ===\n');

  try {
    // Test 1: Send message
    console.log('1. Testing POST /api/messages/send');
    const sendMessageResult = await makeRequest('POST', '/api/messages/send', {
      senderId: 'test_user_1',
      recipientId: 'test_user_2',
      message: 'Hello, this is a test message!',
      senderName: 'Test User',
      messageType: 'text',
    });
    console.log('Status:', sendMessageResult.statusCode);
    console.log('Response:', JSON.stringify(sendMessageResult.body, null, 2));

    // Test 2: Get messages
    console.log('\n2. Testing GET /api/messages/:userId/:friendId');
    const getMessagesResult = await makeRequest('GET', '/api/messages/test_user_1/test_user_2?limit=10');
    console.log('Status:', getMessagesResult.statusCode);
    console.log('Response:', JSON.stringify(getMessagesResult.body, null, 2));

    // Test 3: Mark messages as read
    console.log('\n3. Testing PUT /api/messages/read');
    const markReadResult = await makeRequest('PUT', '/api/messages/read', {
      userId: 'test_user_2',
      friendId: 'test_user_1',
    });
    console.log('Status:', markReadResult.statusCode);
    console.log('Response:', JSON.stringify(markReadResult.body, null, 2));

    console.log('\n✅ Chat API tests completed');
  } catch (error) {
    console.error('❌ Chat API test failed:', error.message);
  }
}

async function testVerificationAPI() {
  console.log('\n=== Testing Verification Code API ===\n');

  try {
    // Test 1: Send verification code
    console.log('1. Testing POST /api/verification/send');
    const sendCodeResult = await makeRequest('POST', '/api/verification/send', {
      email: 'test@example.com',
      purpose: 'email_verification',
    });
    console.log('Status:', sendCodeResult.statusCode);
    console.log('Response:', JSON.stringify(sendCodeResult.body, null, 2));

    // Extract code from response (only available in development)
    const code = sendCodeResult.body.code;
    
    if (code) {
      // Test 2: Verify correct code
      console.log('\n2. Testing POST /api/verification/verify (correct code)');
      const verifyCorrectResult = await makeRequest('POST', '/api/verification/verify', {
        email: 'test@example.com',
        code: code,
        purpose: 'email_verification',
      });
      console.log('Status:', verifyCorrectResult.statusCode);
      console.log('Response:', JSON.stringify(verifyCorrectResult.body, null, 2));
    }

    // Test 3: Verify wrong code (should fail)
    console.log('\n3. Testing POST /api/verification/verify (wrong code)');
    
    // Send new code first
    await makeRequest('POST', '/api/verification/send', {
      email: 'test2@example.com',
      purpose: 'email_verification',
    });
    
    const verifyWrongResult = await makeRequest('POST', '/api/verification/verify', {
      email: 'test2@example.com',
      code: '000000', // Wrong code
      purpose: 'email_verification',
    });
    console.log('Status:', verifyWrongResult.statusCode);
    console.log('Response:', JSON.stringify(verifyWrongResult.body, null, 2));

    console.log('\n✅ Verification API tests completed');
  } catch (error) {
    console.error('❌ Verification API test failed:', error.message);
  }
}

// Run all tests
async function runAllTests() {
  console.log('🚀 Starting API Tests...');
  console.log('Backend URL:', `http://${BASE_URL}:${PORT}`);
  console.log('Make sure your backend server is running!\n');

  await testFriendsAPI();
  await testChatAPI();
  await testVerificationAPI();

  console.log('\n🎉 All API tests completed!\n');
}

// Execute
runAllTests().catch(error => {
  console.error('❌ Test suite failed:', error);
  process.exit(1);
});
