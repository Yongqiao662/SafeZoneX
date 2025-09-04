import 'package:flutter/material.dart';

class ChatMessage {
  final String sender;
  final String message;
  final String time;
  final bool isFromUser;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.time,
    this.isFromUser = false,
  });
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> messages = [
    ChatMessage(
      sender: 'Security',
      message: 'SafeZone+ Security Team here. How can we help?',
      time: '2:31 PM',
    ),
    ChatMessage(
      sender: 'Security',
      message: 'We have your location. Officer Martinez is 3 minutes away.',
      time: '2:33 PM',
    ),
    ChatMessage(
      sender: 'Security',
      message: 'EMERGENCY ALERT RECEIVED. Officer dispatched to your location immediately. Stay calm, help is on the way.',
      time: '2:35 PM',
    ),
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add(ChatMessage(
          sender: 'You',
          message: _messageController.text.trim(),
          time: TimeOfDay.now().format(context),
          isFromUser: true,
        ));
      });
      _messageController.clear();
      
      // Mock auto-reply from security
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          messages.add(ChatMessage(
            sender: 'Security',
            message: 'Thanks for the update. We\'re monitoring your situation closely.',
            time: TimeOfDay.now().format(context),
          ));
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.blue[600]),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campus Security',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: message.isFromUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!message.isFromUser) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue[600],
                          child: Icon(
                            Icons.security,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: message.isFromUser
                                ? Colors.blue[600]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.message,
                                style: TextStyle(
                                  color: message.isFromUser
                                      ? Colors.white
                                      : Colors.grey[900],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                message.time,
                                style: TextStyle(
                                  color: message.isFromUser
                                      ? Colors.white70
                                      : Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (message.isFromUser) ...[
                        SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[400],
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: Text(
                    'Send',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}