// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_dotenv/flutter_dotenv.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:shared_preferences/shared_preferences.dart';

// // class JobPostDetailsPage extends StatefulWidget {
// //   final int jobId;

// //   const JobPostDetailsPage({super.key, required this.jobId});

// //   @override
// //   State<JobPostDetailsPage> createState() => _JobPostDetailsPageState();
// // }

// // class _JobPostDetailsPageState extends State<JobPostDetailsPage> {
// //   final String baseUrl = dotenv.env['BASE_URL'] ?? '';
// //   bool _isLoading = true;
// //   String? _errorMessage;
// //   Map<String, dynamic>? jobData;
// //   List<dynamic> jobRequests = [];
// //   String? _authToken;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadTokenAndFetchJobDetails();
// //   }

// //   Future<void> _loadTokenAndFetchJobDetails() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     _authToken = prefs.getString('access_token');

// //     if (_authToken == null) {
// //       setState(() {
// //         _errorMessage = "Not logged in.";
// //         _isLoading = false;
// //       });
// //       return;
// //     }

// //     await fetchJobDetails();
// //     await fetchJobRequests();
// //   }

// //   Map<String, String> _getAuthHeaders() {
// //     return {
// //       'Authorization': 'Bearer $_authToken',
// //       'Content-Type': 'application/json',
// //     };
// //   }

// //   Future<void> fetchJobDetails() async {
// //     try {
// //       final response = await http.get(
// //         Uri.parse('$baseUrl/api/job-posts/${widget.jobId}/'),
// //         headers: _getAuthHeaders(),
// //       );
// //       print(
// //         '($response)*********************************************************',
// //       );

// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         setState(() {
// //           jobData = data;
// //           _isLoading = false;
// //         });
// //       } else {
// //         setState(() {
// //           _errorMessage =
// //               'Failed to load job details. Status code: ${response.statusCode}';
// //           _isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       setState(() {
// //         _errorMessage = 'Error: ${e.toString()}';
// //         _isLoading = false;
// //       });
// //     }
// //   }

// //   Future<void> fetchJobRequests() async {
// //     try {
// //       var request = http.Request(
// //         'GET',
// //         Uri.parse('$baseUrl/api/job-requests/list/${widget.jobId}'),
// //       );
// //       print(
// //         '($request)*********************************************************',
// //       );
// //       request.headers.addAll({'Authorization': 'Bearer $_authToken'});

// //       http.StreamedResponse response = await request.send();

// //       if (response.statusCode == 200) {
// //         String responseBody = await response.stream.bytesToString();
// //         final List<dynamic> requestData = json.decode(responseBody);
// //         setState(() {
// //           jobRequests = requestData;
// //         });
// //       } else {
// //         print("Job Requests Error: ${response.reasonPhrase}");
// //       }
// //     } catch (e) {
// //       print("Job Requests Exception: $e");
// //     } finally {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }

// //   Future<int?> _hireDriver(int jobRequestId) async {
// //     final url = Uri.parse('$baseUrl/api/job-requests/$jobRequestId/accept/');

// //     try {
// //       final request = http.Request('POST', url);
// //       request.headers.addAll(_getAuthHeaders());
// //       request.body = '';

// //       final response = await request.send();

// //       if (response.statusCode == 200) {
// //         final responseData = await response.stream.bytesToString();
// //         final jsonResponse = json.decode(responseData);

// //         final chatRoomId = jsonResponse['chat_room_id'];
// //         print('Chat Room ID: $chatRoomId');
// //         await fetchJobRequests();
// //         return chatRoomId;
// //       } else {
// //         print('Hire Failed: ${response.reasonPhrase}');
// //       }
// //     } catch (e) {
// //       print('Hire Error: $e');
// //     }
// //     return null;
// //   }

// //   void _connectToChatRoom(int chatRoomId) {
// //     final socketUrl = 'ws://192.168.20.29:8000/ws/chat/$chatRoomId/';
// //     WebSocket.connect(socketUrl)
// //         .then((WebSocket socket) {
// //           print('Connected to WebSocket chat room $chatRoomId');

// //           socket.listen((data) {
// //             final message = json.decode(data);
// //             print('Received: ${message['message']}');
// //           });

// //           // Send a message
// //           socket.add(json.encode({'message': 'Hello!'}));
// //         })
// //         .catchError((error) {
// //           print('WebSocket connection error: $error');
// //         });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Job Post Details')),
// //       body:
// //           _isLoading
// //               ? const Center(child: CircularProgressIndicator())
// //               : _errorMessage != null
// //               ? Center(child: Text(_errorMessage!))
// //               : jobData == null
// //               ? const Center(child: Text("Failed to load data"))
// //               : Padding(
// //                 padding: const EdgeInsets.all(16),
// //                 child: ListView(
// //                   children: [
// //                     const SizedBox(height: 20),
// //                     Text(
// //                       "Title: ${jobData!['title']}",
// //                       style: const TextStyle(fontSize: 20),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Text("Description: ${jobData!['description']}"),
// //                     const SizedBox(height: 8),
// //                     Text("Business Name: ${jobData!['business_name']}"),
// //                     const SizedBox(height: 8),
// //                     Text("Hourly Rate: ${jobData!['hourly_rate']}"),
// //                     const SizedBox(height: 8),
// //                     Text("Per Delivery Rate: ${jobData!['per_delivery_rate']}"),
// //                     const SizedBox(height: 8),
// //                     Text("Start Time: ${jobData!['start_time']}"),
// //                     const SizedBox(height: 8),
// //                     Text("End Time: ${jobData!['end_time']}"),
// //                     const SizedBox(height: 8),

// //                     const Text(
// //                       "Complimentary Benefits:",
// //                       style: TextStyle(fontWeight: FontWeight.bold),
// //                     ),
// //                     if (jobData!['complimentary_benefits'] != null)
// //                       ...List<Widget>.from(
// //                         (jobData!['complimentary_benefits'] as List).map(
// //                           (item) => Text("• $item"),
// //                         ),
// //                       ),
// //                     const SizedBox(height: 16),
// //                     const Text(
// //                       "Applied Members:",
// //                       style: TextStyle(
// //                         fontWeight: FontWeight.bold,
// //                         fontSize: 18,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 8),

// //                     jobRequests.isEmpty
// //                         ? const Text("No drivers have applied yet.")
// //                         : Column(
// //                           children:
// //                               jobRequests.map<Widget>((req) {
// //                                 final bool isAccepted = req['is_accepted'];
// //                                 final int jobRequestId = req['job_request_id'];
// //                                 final int driverId = req['driver_id'];
// //                                 final String driverName = req['driver_name'];

// //                                 return Card(
// //                                   margin: const EdgeInsets.symmetric(
// //                                     vertical: 8,
// //                                   ),
// //                                   child: ListTile(
// //                                     leading: const Icon(Icons.person),
// //                                     title: Text("Name: $driverName"),
// //                                     subtitle: Column(
// //                                       crossAxisAlignment:
// //                                           CrossAxisAlignment.start,
// //                                       children: [
// //                                         Text("Driver ID: $driverId"),
// //                                         Text("Job Request ID: $jobRequestId"),
// //                                         const SizedBox(height: 8),
// //                                         isAccepted
// //                                             ? Row(
// //                                               children: [
// //                                                 const Text(
// //                                                   "Hired",
// //                                                   style: TextStyle(
// //                                                     color: Colors.green,
// //                                                   ),
// //                                                 ),
// //                                                 const SizedBox(width: 16),
// //                                                 ElevatedButton(
// //                                                   onPressed: () {
// //                                                     // Implement chat navigation logic here
// //                                                   },
// //                                                   child: const Text("Chat"),
// //                                                 ),
// //                                               ],
// //                                             )
// //                                             : ElevatedButton(
// //                                               onPressed: () async {
// //                                                 await _hireDriver(jobRequestId);
// //                                               },
// //                                               child: const Text("Hire"),
// //                                             ),
// //                                       ],
// //                                     ),
// //                                   ),
// //                                 );
// //                               }).toList(),
// //                         ),
// //                   ],
// //                 ),
// //               ),
// //     );
// //   }
// // }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_shopkeeper/view/chat.dart';

// class JobPostDetailsPage extends StatefulWidget {
//   final int jobId;

//   const JobPostDetailsPage({super.key, required this.jobId});

//   @override
//   State<JobPostDetailsPage> createState() => _JobPostDetailsPageState();
// }

// class _JobPostDetailsPageState extends State<JobPostDetailsPage> {
//   final String baseUrl = dotenv.env['BASE_URL'] ?? '';
//   bool _isLoading = true;
//   String? _errorMessage;
//   Map<String, dynamic>? jobData;
//   List<dynamic> jobRequests = [];
//   String? _authToken;

//   @override
//   void initState() {
//     super.initState();
//     _loadTokenAndFetchJobDetails();
//   }

//   Future<void> _loadTokenAndFetchJobDetails() async {
//     final prefs = await SharedPreferences.getInstance();
//     _authToken = prefs.getString('access_token');

//     if (_authToken == null) {
//       setState(() {
//         _errorMessage = "Not logged in.";
//         _isLoading = false;
//       });
//       return;
//     }

//     await fetchJobDetails();
//     await fetchJobRequests();
//   }

//   Map<String, String> _getAuthHeaders() {
//     return {
//       'Authorization': 'Bearer $_authToken',
//       'Content-Type': 'application/json',
//     };
//   }

//   Future<void> fetchJobDetails() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/job-posts/${widget.jobId}/'),
//         headers: _getAuthHeaders(),
//       );
//       print(
//         '($response)*********************************************************',
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           jobData = data;
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _errorMessage =
//               'Failed to load job details. Status code: ${response.statusCode}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error: ${e.toString()}';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> fetchJobRequests() async {
//     try {
//       var request = http.Request(
//         'GET',
//         Uri.parse('$baseUrl/api/job-requests/list/${widget.jobId}'),
//       );
//       print(
//         '($request)*********************************************************',
//       );
//       request.headers.addAll({'Authorization': 'Bearer $_authToken'});

//       http.StreamedResponse response = await request.send();

//       if (response.statusCode == 200) {
//         String responseBody = await response.stream.bytesToString();
//         final List<dynamic> requestData = json.decode(responseBody);
//         setState(() {
//           jobRequests = requestData;
//         });
//       } else {
//         print("Job Requests Error: ${response.reasonPhrase}");
//       }
//     } catch (e) {
//       print("Job Requests Exception: $e");
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _hireDriver(int jobRequestId) async {
//     final url = Uri.parse('$baseUrl/api/job-requests/$jobRequestId/accept/');

//     try {
//       final response = await http.post(
//         url,
//         headers: _getAuthHeaders(),
//         body: json.encode({}), // Send empty JSON body
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         print('Hire Success: $responseData');
//         await fetchJobRequests(); // Refresh UI
//       } else {
//         print('Hire Failed: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       print('Hire Error: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Job Post Details')),
//       body:
//           _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : _errorMessage != null
//               ? Center(child: Text(_errorMessage!))
//               : jobData == null
//               ? const Center(child: Text("Failed to load data"))
//               : Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: ListView(
//                   children: [
//                     // if (jobData!['business_image'] != null)
//                     //   Image.network(
//                     //     'https://anjalitechfifo.pythonanywhere.com${jobData!['business_image']}',
//                     //     height: 200,
//                     //     errorBuilder:
//                     //         (_, __, ___) =>
//                     //             const Icon(Icons.broken_image, size: 100),
//                     //   ),
//                     const SizedBox(height: 20),
//                     Text(
//                       "Title: ${jobData!['title']}",
//                       style: const TextStyle(fontSize: 20),
//                     ),
//                     const SizedBox(height: 8),
//                     Text("Description: ${jobData!['description']}"),
//                     const SizedBox(height: 8),
//                     Text("Business Name: ${jobData!['business_name']}"),
//                     const SizedBox(height: 8),
//                     Text("Hourly Rate: ${jobData!['hourly_rate']}"),
//                     const SizedBox(height: 8),
//                     Text("Per Delivery Rate: ${jobData!['per_delivery_rate']}"),
//                     const SizedBox(height: 8),
//                     Text("Start Time: ${jobData!['start_time']}"),
//                     const SizedBox(height: 8),
//                     Text("End Time: ${jobData!['end_time']}"),
//                     const SizedBox(height: 8),

//                     const Text(
//                       "Complimentary Benefits:",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     if (jobData!['complimentary_benefits'] != null)
//                       ...List<Widget>.from(
//                         (jobData!['complimentary_benefits'] as List).map(
//                           (item) => Text("• $item"),
//                         ),
//                       ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       "Applied Members:",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                     const SizedBox(height: 8),

//                     jobRequests.isEmpty
//                         ? const Text("No drivers have applied yet.")
//                         : Column(
//                           children:
//                               jobRequests.map<Widget>((req) {
//                                 final bool isAccepted = req['is_accepted'];
//                                 final int jobRequestId = req['job_request_id'];
//                                 final int driverId = req['driver_id'];
//                                 final String driverName = req['driver_name'];

//                                 return Card(
//                                   margin: const EdgeInsets.symmetric(
//                                     vertical: 8,
//                                   ),
//                                   child: ListTile(
//                                     leading: const Icon(Icons.person),
//                                     title: Text("Name: $driverName"),
//                                     subtitle: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text("Driver ID: $driverId"),
//                                         Text("Job Request ID: $jobRequestId"),
//                                         const SizedBox(height: 8),
//                                         isAccepted
//                                             ? Row(
//                                               children: [
//                                                 const Text(
//                                                   "Hired",
//                                                   style: TextStyle(
//                                                     color: Colors.green,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(width: 16),
//                                                 ElevatedButton(
//                                                   onPressed: () {
//                                                     Navigator.push(
//                                                       context,
//                                                       MaterialPageRoute(
//                                                         builder:
//                                                             (
//                                                               context,
//                                                             ) => ChatScreen(
//                                                               jobRequestId:
//                                                                   jobRequestId,
//                                                               // currentUserId:
//                                                               //     currentUserId,
//                                                             ),
//                                                       ),
//                                                     );
//                                                   },
//                                                   child: const Text("Chat"),
//                                                 ),
//                                               ],
//                                             )
//                                             : ElevatedButton(
//                                               onPressed: () async {
//                                                 await _hireDriver(jobRequestId);
//                                               },
//                                               child: const Text("Hire"),
//                                             ),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               }).toList(),
//                         ),
//                   ],
//                 ),
//               ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/view/chat.dart';

class JobPostDetailsPage extends StatefulWidget {
  final int jobId;

  const JobPostDetailsPage({super.key, required this.jobId});

  @override
  State<JobPostDetailsPage> createState() => _JobPostDetailsPageState();
}

class _JobPostDetailsPageState extends State<JobPostDetailsPage> {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isHiring = false;
  String? _errorMessage;
  Map<String, dynamic>? jobData;
  List<dynamic> jobRequests = [];
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchJobDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTokenAndFetchJobDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('access_token');

      if (_authToken == null) {
        setState(() {
          _errorMessage = "Authentication required. Please log in.";
          _isLoading = false;
        });
        return;
      }

      await Future.wait([
        fetchJobDetails(),
        fetchJobRequests(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchJobDetails() async {
    try {
      print('🔍 Fetching job details for ID: ${widget.jobId}');
      print('🌐 BASE_URL: $baseUrl');
      print('🔑 Auth token available: ${_authToken != null}');
      
      final url = '$baseUrl/api/job-posts/${widget.jobId}/';
      print('📡 Request URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getAuthHeaders(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('📊 Response status: ${response.statusCode}');
      print('📄 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Job details loaded successfully');
        if (mounted) {
          setState(() {
            jobData = data;
          });
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception('Job post not found.');
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load job details (${response.statusCode})');
      }
    } catch (e) {
      print('💥 Error fetching job details: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
      rethrow;
    }
  }

  Future<void> fetchJobRequests() async {
    try {
      print('🔍 Fetching job requests for job ID: ${widget.jobId}');
      
      final url = '$baseUrl/api/job-requests/list/${widget.jobId}';
      print('📡 Job requests URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getAuthHeaders(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Job requests timeout');
        },
      );

      print('📊 Job requests response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> requestData = json.decode(response.body);
        print('✅ Job requests loaded: ${requestData.length} requests');
        if (mounted) {
          setState(() {
            jobRequests = requestData;
          });
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access to job requests');
      } else {
        print("❌ Job Requests Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("💥 Job Requests Exception: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _hireDriver(int jobRequestId) async {
    if (_isHiring) return;

    setState(() {
      _isHiring = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/job-requests/$jobRequestId/accept/'),
        headers: _getAuthHeaders(),
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Driver hired successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          await fetchJobRequests(); // Refresh the list
        }
      } else {
        throw Exception('Failed to hire driver (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error hiring driver: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isHiring = false;
        });
      }
    }
  }

  Widget _buildJobInfoCard() {
    if (jobData == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Job data not available'),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jobData!['title']?.toString() ?? 'No Title',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business, 'Business', jobData!['business_name']),
            _buildInfoRow(Icons.description, 'Description', jobData!['description']),
            _buildInfoRow(Icons.attach_money, 'Hourly Rate', '${jobData!['hourly_rate']}'),
            _buildInfoRow(Icons.local_shipping, 'Per Delivery', '${jobData!['per_delivery_rate']}'),
            _buildInfoRow(Icons.schedule, 'Start Time', jobData!['start_time']),
            _buildInfoRow(Icons.schedule_outlined, 'End Time', jobData!['end_time']),
            
            if (jobData!['complimentary_benefits'] != null && 
                jobData!['complimentary_benefits'] is List &&
                (jobData!['complimentary_benefits'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.card_giftcard, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text(
                    'Benefits',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...(jobData!['complimentary_benefits'] as List).map<Widget>(
                (item) => Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.toString())),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF757575)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF212121),
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                Text(
                  'Applicants (${jobRequests.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (jobRequests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF757575)),
                    SizedBox(width: 12),
                    Text(
                      'No drivers have applied yet.',
                      style: TextStyle(color: Color(0xFF757575)),
                    ),
                  ],
                ),
              )
            else
              ...jobRequests.map<Widget>((req) {
                final bool isAccepted = req['is_accepted'] ?? false;
                final int jobRequestId = req['job_request_id'] ?? 0;
                final int driverId = req['driver_id'] ?? 0;
                final String driverName = req['driver_name'] ?? 'Unknown Driver';

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(12),
                    color: isAccepted ? const Color(0xFFF1F8E9) : Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isAccepted ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                              child: Text(
                                driverName.isNotEmpty ? driverName[0].toUpperCase() : 'D',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Driver ID: $driverId',
                                    style: const TextStyle(
                                      color: Color(0xFF757575),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Request ID: $jobRequestId',
                                    style: const TextStyle(
                                      color: Color(0xFF757575),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (isAccepted)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'HIRED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          jobRequestId: jobRequestId,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat),
                                  label: const Text('Chat'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isHiring ? null : () async {
                                await _hireDriver(jobRequestId);
                              },
                              icon: _isHiring 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.how_to_reg),
                              label: Text(_isHiring ? 'Hiring...' : 'Hire Driver'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadTokenAndFetchJobDetails();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading job details...'),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadTokenAndFetchJobDetails();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTokenAndFetchJobDetails,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _buildJobInfoCard(),
                            _buildApplicantsList(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}