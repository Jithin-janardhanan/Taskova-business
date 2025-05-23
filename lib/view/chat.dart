
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class ChatScreen extends StatefulWidget {
//   final int jobRequestId;

//   const ChatScreen({super.key, required this.jobRequestId});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.20.29:8000';
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();

//   WebSocketChannel? _channel;
//   List<Map<String, dynamic>> _messages = [];
//   String? _authToken;
//   int? _chatRoomId;
//   int? _driverId;
//   int? _jobId;
//   int? _currentUserId;
//   bool _isLoading = true;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     print(
//       'ChatScreen initState called with jobRequestId: ${widget.jobRequestId}',
//     );
//     // TEMPORARY: Set current user ID for testing
//     _currentUserId = 8; // Change this to test different users
//     _initializeChat();
//   }

//   Future<void> _initializeChat() async {
//     print('Starting chat initialization...');

//     await _loadAuthToken();
//     print('Auth token loaded: ${_authToken != null}');

//     if (_authToken != null) {
//       await _fetchChatRoomDetails();
//       print('Chat room details fetched. ChatRoomId: $_chatRoomId');

//       if (_chatRoomId != null) {
//         await _loadChatHistory();
//         print('Chat history loaded. Messages count: ${_messages.length}');
//         _connectWebSocket();
//       } else {
//         setState(() {
//           _errorMessage = "Failed to get chat room ID";
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _loadAuthToken() async {
//     print('Loading auth token...');
//     final prefs = await SharedPreferences.getInstance();
//     _authToken = prefs.getString('access_token');

//     print('Auth token found: ${_authToken != null}');

//     // Get current user ID from shared preferences - handle both int and string
//     try {
//       _currentUserId = prefs.getInt('user_id');
//     } catch (e) {
//       // If stored as string, try to parse it
//       final userIdString = prefs.getString('user_id');
//       if (userIdString != null) {
//         _currentUserId = int.tryParse(userIdString);
//       }
//     }

//     // If still null, set default for testing
//     _currentUserId ??= 8;

//     print('Current user ID: $_currentUserId');

//     if (_authToken == null) {
//       print('No auth token found');
//       setState(() {
//         _errorMessage = "Not logged in.";
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _fetchCurrentUserInfo() async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//           '$baseUrl/api/user/profile/',
//         ), // Replace with your user profile endpoint
//         headers: _getAuthHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final userData = json.decode(response.body);
//         _currentUserId = userData['id'];

//         // Store for future use
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setInt('user_id', _currentUserId!);
//       }
//     } catch (e) {
//       print('Error fetching user info: $e');
//     }
//   }

//   Map<String, String> _getAuthHeaders() {
//     return {
//       'Authorization': 'Bearer $_authToken',
//       'Content-Type': 'application/json',
//     };
//   }

//   Future<void> _fetchChatRoomDetails() async {
//     print(
//       'Fetching chat room details for jobRequestId: ${widget.jobRequestId}',
//     );

//     try {
//       final url = '$baseUrl/api/job-requests/${widget.jobRequestId}/accept/';
//       print('Making request to: $url');

//       final response = await http.get(
//         Uri.parse(url),
//         headers: _getAuthHeaders(),
//       );

//       print('Chat room API response status: ${response.statusCode}');
//       print('Chat room API response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _chatRoomId = data['chat_room_id'];
//           _driverId = data['driver_id'];
//           _jobId = data['job_id'];
//         });
//         print(
//           'Chat Room Details - ID: $_chatRoomId, Driver: $_driverId, Job: $_jobId',
//         );
//       } else {
//         print(
//           'Failed to get chat room details. Status: ${response.statusCode}',
//         );
//         setState(() {
//           _errorMessage =
//               'Failed to get chat room details: ${response.statusCode}\n${response.body}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Exception in _fetchChatRoomDetails: $e');
//       setState(() {
//         _errorMessage = 'Error fetching chat room details: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _loadChatHistory() async {
//     print('Loading chat history for chatRoomId: $_chatRoomId');

//     try {
//       final url = '$baseUrl/api/chat-history/$_chatRoomId/';
//       print('Making request to: $url');

//       final response = await http.get(
//         Uri.parse(url),
//         headers: _getAuthHeaders(),
//       );

//       print('Chat history API response status: ${response.statusCode}');
//       print('Chat history API response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final List<dynamic> chatHistory = json.decode(response.body);
//         setState(() {
//           _messages =
//               chatHistory.map((msg) => Map<String, dynamic>.from(msg)).toList();
//           _isLoading = false;
//         });
//         print(
//           'Chat history loaded successfully. Messages count: ${_messages.length}',
//         );
//         _scrollToBottom();
//       } else {
//         print('Failed to load chat history. Status: ${response.statusCode}');
//         setState(() {
//           _errorMessage =
//               'Failed to load chat history: ${response.statusCode}\n${response.body}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Exception in _loadChatHistory: $e');
//       setState(() {
//         _errorMessage = 'Error loading chat history: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   void _connectWebSocket() {
//     try {
//       _channel = WebSocketChannel.connect(
//         Uri.parse(
//           'ws://192.168.20.29:8000/ws/chat/$_chatRoomId/?token=$_authToken',
//         ),
//       );

//       _channel!.stream.listen(
//         (data) {
//           final message = json.decode(data);
//           setState(() {
//             _messages.add(message);
//           });
//           _scrollToBottom();
//         },
//         onError: (error) {
//           print('WebSocket Error: $error');
//         },
//         onDone: () {
//           print('WebSocket connection closed');
//         },
//       );
//     } catch (e) {
//       print('WebSocket connection error: $e');
//     }
//   }

//   void _sendMessage() {
//     if (_messageController.text.trim().isEmpty || _channel == null) return;

//     final message = {
//       'message': _messageController.text.trim(),
//       'timestamp': DateTime.now().toIso8601String(),
//     };

//     _channel!.sink.add(json.encode(message));
//     _messageController.clear();
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   Widget _buildMessage(Map<String, dynamic> message) {
//     // Extract sender information from the API response structure
//     final Map<String, dynamic>? sender = message['sender'];
//     final int? senderId = sender?['id'];
//     final String senderUsername = sender?['username'] ?? 'Unknown';
//     final String messageText = message['message'] ?? '';
//     final String timestamp = message['timestamp'] ?? '';

//     // Check if the message is from the current user
//     final bool isMe = senderId == _currentUserId;

//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       child: Row(
//         mainAxisAlignment:
//             isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//         children: [
//           Container(
//             constraints: BoxConstraints(
//               maxWidth: MediaQuery.of(context).size.width * 0.75,
//             ),
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//             decoration: BoxDecoration(
//               color: isMe ? Colors.blue[500] : Colors.grey[300],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Show sender name for messages from others
//                 if (!isMe)
//                   Text(
//                     senderUsername,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                       color: Colors.black54,
//                     ),
//                   ),
//                 if (!isMe) const SizedBox(height: 2),
//                 Text(
//                   messageText,
//                   style: TextStyle(
//                     color: isMe ? Colors.white : Colors.black87,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _formatTimestamp(timestamp),
//                   style: TextStyle(
//                     color: isMe ? Colors.white70 : Colors.black54,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatTimestamp(String timestamp) {
//     try {
//       final DateTime dateTime = DateTime.parse(timestamp);
//       final DateTime now = DateTime.now();
//       final Duration difference = now.difference(dateTime);

//       if (difference.inDays > 0) {
//         return '${difference.inDays}d ago';
//       } else if (difference.inHours > 0) {
//         return '${difference.inHours}h ago';
//       } else if (difference.inMinutes > 0) {
//         return '${difference.inMinutes}m ago';
//       } else {
//         return 'Just now';
//       }
//     } catch (e) {
//       return '';
//     }
//   }

//   @override
//   void dispose() {
//     _channel?.sink.close();
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat - Job Request #${widget.jobRequestId}'),
//         backgroundColor: Colors.blue[600],
//         foregroundColor: Colors.white,
//       ),
//       body:
//           _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : _errorMessage != null
//               ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       _errorMessage!,
//                       style: const TextStyle(color: Colors.red),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _initializeChat,
//                       child: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               )
//               : Column(
//                 children: [
//                   // Chat info header
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     color: Colors.grey[100],
//                     child: Row(
//                       children: [
//                         const Icon(Icons.info_outline, color: Colors.blue),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Chat Room ID: $_chatRoomId | Job ID: $_jobId',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   // Messages list
//                   Expanded(
//                     child:
//                         _messages.isEmpty
//                             ? const Center(
//                               child: Text(
//                                 'No messages yet. Start the conversation!',
//                                 style: TextStyle(color: Colors.grey),
//                               ),
//                             )
//                             : ListView.builder(
//                               controller: _scrollController,
//                               itemCount: _messages.length,
//                               itemBuilder: (context, index) {
//                                 return _buildMessage(_messages[index]);
//                               },
//                             ),
//                   ),
//                   // Message input
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.3),
//                           spreadRadius: 1,
//                           blurRadius: 3,
//                           offset: const Offset(0, -1),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _messageController,
//                             decoration: InputDecoration(
//                               hintText: 'Type a message...',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(24),
//                                 borderSide: BorderSide.none,
//                               ),
//                               filled: true,
//                               fillColor: Colors.grey[100],
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 8,
//                               ),
//                             ),
//                             onSubmitted: (_) => _sendMessage(),
//                             maxLines: null,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         CircleAvatar(
//                           backgroundColor: Colors.blue[600],
//                           child: IconButton(
//                             icon: const Icon(Icons.send, color: Colors.white),
//                             onPressed: _sendMessage,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  final int jobRequestId;

  const ChatScreen({Key? key, required this.jobRequestId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.20.29:8000';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  WebSocketChannel? _channel;
  List<Map<String, dynamic>> _messages = [];
  String? _authToken;
  int? _chatRoomId;
  int? _driverId;
  int? _jobId;
  int? _currentUserId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('ChatScreen initState called with jobRequestId: ${widget.jobRequestId}');
    // TEMPORARY: Set current user ID for testing
    _currentUserId = 8; // Change this to test different users
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print('Starting chat initialization...');
    
    await _loadAuthToken();
    print('Auth token loaded: ${_authToken != null}');
    
    if (_authToken != null) {
      await _fetchChatRoomDetails();
      print('Chat room details fetched. ChatRoomId: $_chatRoomId');
      
      if (_chatRoomId != null) {
        await _loadChatHistory();
        print('Chat history loaded. Messages count: ${_messages.length}');
        _connectWebSocket();
      } else {
        setState(() {
          _errorMessage = "Failed to get chat room ID";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAuthToken() async {
    print('Loading auth token...');
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('access_token');
    
    print('Auth token found: ${_authToken != null}');
    
    // Get current user ID from shared preferences - handle both int and string
    try {
      _currentUserId = prefs.getInt('user_id');
    } catch (e) {
      // If stored as string, try to parse it
      final userIdString = prefs.getString('user_id');
      if (userIdString != null) {
        _currentUserId = int.tryParse(userIdString);
      }
    }
    
    // If user ID is not found in SharedPreferences, fetch from API
    if (_currentUserId == null && _authToken != null) {
      await _fetchCurrentUserInfo();
    }
    
    print('Current user ID: $_currentUserId');
    
    if (_authToken == null) {
      print('No auth token found');
      setState(() {
        _errorMessage = "Not logged in.";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCurrentUserInfo() async {
    print('Fetching current user info from API...');
    try {
      // Replace with your actual user profile/info endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile/'), // or /api/auth/user/ or whatever your endpoint is
        headers: _getAuthHeaders(),
      );

      print('User info API response status: ${response.statusCode}');
      print('User info API response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _currentUserId = userData['id'];
        
        // Store for future use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', _currentUserId!);
        
        print('Current user ID fetched and stored: $_currentUserId');
      } else {
        print('Failed to fetch user info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  

  Map<String, String> _getAuthHeaders() {
    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _fetchChatRoomDetails() async {
    print('Fetching chat room details for jobRequestId: ${widget.jobRequestId}');
    
    try {
      final url = '$baseUrl/api/job-requests/${widget.jobRequestId}/accept/';
      print('Making request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getAuthHeaders(),
      );

      print('Chat room API response status: ${response.statusCode}');
      print('Chat room API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _chatRoomId = data['chat_room_id'];
          _driverId = data['driver_id'];
          _jobId = data['job_id'];
        });
        print('Chat Room Details - ID: $_chatRoomId, Driver: $_driverId, Job: $_jobId');
      } else {
        print('Failed to get chat room details. Status: ${response.statusCode}');
        setState(() {
          _errorMessage = 'Failed to get chat room details: ${response.statusCode}\n${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception in _fetchChatRoomDetails: $e');
      setState(() {
        _errorMessage = 'Error fetching chat room details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    print('Loading chat history for chatRoomId: $_chatRoomId');
    
    try {
      final url = '$baseUrl/api/chat-history/$_chatRoomId/';
      print('Making request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getAuthHeaders(),
      );

      print('Chat history API response status: ${response.statusCode}');
      print('Chat history API response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> chatHistory = json.decode(response.body);
        setState(() {
          _messages = chatHistory.map((msg) => Map<String, dynamic>.from(msg)).toList();
          _isLoading = false;
        });
        print('Chat history loaded successfully. Messages count: ${_messages.length}');
        _scrollToBottom();
      } else {
        print('Failed to load chat history. Status: ${response.statusCode}');
        setState(() {
          _errorMessage = 'Failed to load chat history: ${response.statusCode}\n${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception in _loadChatHistory: $e');
      setState(() {
        _errorMessage = 'Error loading chat history: $e';
        _isLoading = false;
      });
    }
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.20.29:8000/ws/chat/$_chatRoomId/?token=$_authToken'),
      );

      _channel!.stream.listen(
        (data) {
          final message = json.decode(data);
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        },
        onError: (error) {
          print('WebSocket Error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('WebSocket connection error: $e');
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _channel == null) return;

    final message = {
      'message': _messageController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(json.encode(message));
    _messageController.clear();
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

  Widget _buildMessage(Map<String, dynamic> message) {
    // Extract sender information from the API response structure
    final Map<String, dynamic>? sender = message['sender'];
    final int? senderId = sender?['id'];
    final String senderUsername = sender?['username'] ?? 'Unknown';
    final String messageText = message['message'] ?? '';
    final String timestamp = message['timestamp'] ?? '';
    
    // Check if the message is from the current user
    final bool isMe = senderId == _currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[500] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show sender name for messages from others
                if (!isMe)
                  Text(
                    senderUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                if (!isMe) const SizedBox(height: 2),
                Text(
                  messageText,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - Job Request #${widget.jobRequestId}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeChat,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Chat info header
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Chat Room ID: $_chatRoomId | Job ID: $_jobId',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Messages list
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet. Start the conversation!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                return _buildMessage(_messages[index]);
                              },
                            ),
                    ),
                    // Message input
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, -1),
                          ),
                        ],
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
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.blue[600],
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
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