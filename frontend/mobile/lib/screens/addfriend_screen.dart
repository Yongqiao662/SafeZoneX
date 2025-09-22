import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Friend {
  final String id;
  final String name;
  final String username;
  final String email;
  final bool isOnline;
  final String lastSeen;
  final String profileColor;
  final String location;
  final String locationUpdated;

  Friend({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.isOnline,
    required this.lastSeen,
    required this.profileColor,
    required this.location,
    required this.locationUpdated,
  });
}

class ChatMessage {
  final String id;
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String status; // sent, delivered, read

  ChatMessage({
    required this.id,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.status = 'delivered',
  });
}

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _searchTextController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _searchAnimationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _searchAnimation;
  
  List<Friend> allFriends = [
    Friend(
      id: '1',
      name: 'Sarah Wilson',
      username: 'sarah_w',
      email: 'sarah.wilson@university.edu',
      isOnline: true,
      lastSeen: 'Online',
      profileColor: 'purple',
      location: 'Library - Level 3',
      locationUpdated: '2 min ago',
    ),
    Friend(
      id: '2',
      name: 'Mike Chen',
      username: 'mike_chen',
      email: 'mike.chen@university.edu',
      isOnline: false,
      lastSeen: '2 minutes ago',
      profileColor: 'blue',
      location: 'Engineering Building',
      locationUpdated: '15 min ago',
    ),
    Friend(
      id: '3',
      name: 'Emma Davis',
      username: 'emma_d',
      email: 'emma.davis@university.edu',
      isOnline: true,
      lastSeen: 'Online',
      profileColor: 'green',
      location: 'Student Center',
      locationUpdated: '1 min ago',
    ),
    Friend(
      id: '4',
      name: 'Alex Thompson',
      username: 'alex_t',
      email: 'alex.thompson@university.edu',
      isOnline: false,
      lastSeen: '1 hour ago',
      profileColor: 'orange',
      location: 'Dormitory Block A',
      locationUpdated: '1 hour ago',
    ),
  ];

  List<Friend> searchResults = [];
  List<Friend> filteredFriends = [];
  String searchQuery = '';
  bool isSearching = false;

  // Mock chat data for different friends
  Map<String, List<ChatMessage>> chatHistory = {
    '1': [
      ChatMessage(
        id: '1',
        message: 'Hey! Are you free to walk to the dining hall together?',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      ),
      ChatMessage(
        id: '2',
        message: 'Sure! I\'m at the library right now. Give me 5 minutes?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 28)),
      ),
      ChatMessage(
        id: '3',
        message: 'Perfect! I\'ll wait for you at the main entrance',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 25)),
      ),
      ChatMessage(
        id: '4',
        message: 'On my way! Thanks for walking with me 😊',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 20)),
      ),
    ],
    '2': [
      ChatMessage(
        id: '1',
        message: 'Did you finish the assignment for Prof. Martinez?',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
      ),
      ChatMessage(
        id: '2',
        message: 'Yes! Want to study together for the exam next week?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(hours: 1, minutes: 45)),
      ),
      ChatMessage(
        id: '3',
        message: 'Definitely! Library tomorrow at 3 PM?',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(hours: 1, minutes: 30)),
      ),
    ],
    '3': [
      ChatMessage(
        id: '1',
        message: 'Emergency! Lost my keys somewhere on campus',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 45)),
      ),
      ChatMessage(
        id: '2',
        message: 'Oh no! Did you check the student center lost & found?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 40)),
      ),
      ChatMessage(
        id: '3',
        message: 'Found them! They were in my backpack pocket all along 🤦‍♀️',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 35)),
      ),
      ChatMessage(
        id: '4',
        message: 'Haha classic! Glad you found them. Want to grab coffee?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      ),
    ],
    '4': [
      ChatMessage(
        id: '1',
        message: 'Hey! Are you planning to attend the campus safety workshop tomorrow?',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(hours: 3)),
      ),
      ChatMessage(
        id: '2',
        message: 'I completely forgot about it! What time was it again?',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: 30)),
      ),
      ChatMessage(
        id: '3',
        message: '2 PM at the main auditorium. It\'s about the new SafeZoneX app!',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    filteredFriends = allFriends;
    _initAnimations();
    _fadeController.value = 1.0;
    _slideController.value = 1.0;
    _searchAnimationController.value = 1.0;
    _searchTextController.addListener(_onSearchChanged);
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchTextController.text.toLowerCase();
      isSearching = searchQuery.isNotEmpty;
      
      if (searchQuery.isEmpty) {
        filteredFriends = allFriends;
        searchResults = [];
      } else {
        searchResults = _simulateUserSearch(searchQuery);
        filteredFriends = allFriends.where((friend) =>
          friend.name.toLowerCase().contains(searchQuery) ||
          friend.username.toLowerCase().contains(searchQuery) ||
          friend.email.toLowerCase().contains(searchQuery)
        ).toList();
      }
    });
  }

  List<Friend> _simulateUserSearch(String query) {
    List<Friend> allUsers = [
      ...allFriends,
      Friend(
        id: '5',
        name: 'Jessica Park',
        username: 'jessica_park',
        email: 'jessica.park@university.edu',
        isOnline: false,
        lastSeen: 'Not added',
        profileColor: 'pink',
        location: 'Unknown',
        locationUpdated: 'Never',
      ),
      Friend(
        id: '6',
        name: 'David Kim',
        username: 'david_kim',
        email: 'david.kim@university.edu',
        isOnline: true,
        lastSeen: 'Not added',
        profileColor: 'cyan',
        location: 'Unknown',
        locationUpdated: 'Never',
      ),
    ];

    return allUsers.where((user) =>
      !allFriends.any((friend) => friend.id == user.id) &&
      (user.name.toLowerCase().contains(query) ||
       user.username.toLowerCase().contains(query) ||
       user.email.toLowerCase().contains(query))
    ).toList();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchAnimationController.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f1e),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildSearchSection(),
                        const SizedBox(height: 30),
                        if (isSearching && searchResults.isNotEmpty)
                          _buildSearchResults(),
                        if (isSearching && searchResults.isEmpty && searchQuery.isNotEmpty)
                          _buildNoResults(),
                        if (!isSearching || filteredFriends.isNotEmpty)
                          _buildFriendsList(),
                        const SizedBox(height: 100), // Extra padding for bottom navigation
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.people,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Friends',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showAddFriendDialog(),
              icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _searchAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchTextController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search friends by name, username, or email...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchTextController.clear();
                        _onSearchChanged();
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Search Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          ...searchResults.map((user) => _buildSearchResultItem(user)).toList(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Friend user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildProfileAvatar(user, 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _addFriend(user),
              icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.search_off,
                color: Colors.white.withOpacity(0.5),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different username or email',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Text(
                  isSearching ? 'Matching Friends' : 'My Friends',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredFriends.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...filteredFriends.map((friend) => _buildFriendItem(friend)).toList(),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Friend friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileAvatar(friend, 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: friend.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      friend.lastSeen,
                      style: TextStyle(
                        fontSize: 12,
                        color: friend.isOnline 
                            ? Colors.green 
                            : Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.blue.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${friend.location} • ${friend.locationUpdated}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@${friend.username}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _openChat(friend),
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(Friend friend, double size) {
    Color avatarColor;
    switch (friend.profileColor) {
      case 'purple':
        avatarColor = Colors.deepPurple;
        break;
      case 'blue':
        avatarColor = Colors.blue;
        break;
      case 'green':
        avatarColor = Colors.green;
        break;
      case 'orange':
        avatarColor = Colors.orange;
        break;
      case 'pink':
        avatarColor = Colors.pink;
        break;
      case 'cyan':
        avatarColor = Colors.cyan;
        break;
      default:
        avatarColor = Colors.deepPurple;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [avatarColor, avatarColor.withOpacity(0.7)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: avatarColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              friend.name.split(' ').map((name) => name[0]).take(2).join(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (friend.isOnline)
            Positioned(
              bottom: size * 0.05,
              right: size * 0.05,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddFriendDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF1e1a3e),
              Color(0xFF0f0f1e),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Friends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Use the search bar above to find friends by their username or email address.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _addFriend(Friend user) {
    HapticFeedback.lightImpact();
    setState(() {
      allFriends.add(Friend(
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        isOnline: user.isOnline,
        lastSeen: user.isOnline ? 'Online' : 'Just added',
        profileColor: user.profileColor,
        location: user.isOnline ? 'Campus Area' : 'Unknown',
        locationUpdated: user.isOnline ? 'Just now' : 'Never',
      ));
      _onSearchChanged();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${user.name} as friend'),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openChat(Friend friend) {
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          friend: friend,
          messages: chatHistory[friend.id] ?? [],
        ),
      ),
    );
  }
}

// ChatScreen Implementation
class ChatScreen extends StatefulWidget {
  final Friend friend;
  final List<ChatMessage> messages;

  const ChatScreen({
    Key? key,
    required this.friend,
    required this.messages,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> _messages;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.messages);
    _initAnimations();
    _startAnimation();
    
    // Auto-scroll to bottom when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  void _startAnimation() {
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: _messageController.text.trim(),
      isMe: true,
      timestamp: DateTime.now(),
      status: 'sent',
    );

    setState(() {
      _messages.add(message);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate friend typing and response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            message: _getRandomResponse(),
            isMe: false,
            timestamp: DateTime.now(),
            status: 'delivered',
          ));
        });
        _scrollToBottom();
      }
    });
  }

  String _getRandomResponse() {
    final responses = [
      'Got it! 👍',
      'Sounds good to me!',
      'Thanks for letting me know',
      'Absolutely!',
      'I agree completely',
      'That makes sense',
      'Perfect timing!',
      'I was just thinking the same thing',
      'Let\'s do it!',
      'Great idea! 💡',
    ];
    return responses[(DateTime.now().millisecondsSinceEpoch % responses.length)];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getAvatarColor() {
    switch (widget.friend.profileColor) {
      case 'purple':
        return Colors.deepPurple;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'cyan':
        return Colors.cyan;
      default:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f1e),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildChatHeader(),
                Expanded(
                  child: _buildMessagesList(),
                ),
                _buildTypingIndicator(),
                _buildMessageInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_getAvatarColor(), _getAvatarColor().withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    widget.friend.name.split(' ').map((name) => name[0]).take(2).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.friend.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.friend.isOnline ? 'Online' : widget.friend.lastSeen,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.friend.isOnline 
                        ? Colors.green 
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Show friend info or options
            },
            icon: Icon(
              Icons.more_vert,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isFirstMessageOfDay = index == 0 || 
            !_isSameDay(_messages[index - 1].timestamp, message.timestamp);
        
        return Column(
          children: [
            if (isFirstMessageOfDay) _buildDateSeparator(message.timestamp),
            _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getAvatarColor(), _getAvatarColor().withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.friend.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                      )
                    : null,
                color: message.isMe ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: message.isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: message.isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      if (message.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == 'read' ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.status == 'read' ? Colors.blue : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) const SizedBox(width: 32),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildTypingIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isTyping ? 40 : 0,
      child: _isTyping
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_getAvatarColor(), _getAvatarColor().withOpacity(0.7)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.friend.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.friend.name.split(' ')[0]} is typing',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              splashRadius: 24,
            ),
          ),
        ],
      ),
    );
  }
}