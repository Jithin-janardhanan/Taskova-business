// import 'dart:convert';
// import 'dart:math';
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
//   List<dynamic> filteredJobRequests = [];
//   String? _authToken;

//   // Business location data
//   double? businessLatitude;
//   double? businessLongitude;

//   // Filter variables
//   String _selectedFilter = 'All';
//   double _maxDistance = 50.0; // Default max distance in miles
//   double _minRating = 0.0; // Default min rating

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
//           // Save business coordinates
//           if (data['business_detail'] != null) {
//             businessLatitude = data['business_detail']['latitude']?.toDouble();
//             businessLongitude =
//                 data['business_detail']['longitude']?.toDouble();
//           }
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
//           _applyFilters();
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

//   // Calculate distance between two coordinates using Haversine formula
//   double _calculateDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const double earthRadius = 3959; // Earth's radius in miles

//     double dLat = _degreesToRadians(lat2 - lat1);
//     double dLon = _degreesToRadians(lon2 - lon1);

//     double a =
//         sin(dLat / 2) * sin(dLat / 2) +
//         cos(_degreesToRadians(lat1)) *
//             cos(_degreesToRadians(lat2)) *
//             sin(dLon / 2) *
//             sin(dLon / 2);

//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));

//     return earthRadius * c;
//   }

//   double _degreesToRadians(double degrees) {
//     return degrees * (pi / 180);
//   }

//   // Get distance between driver and business
//   double? _getDriverDistance(Map<String, dynamic> request) {
//     if (businessLatitude == null ||
//         businessLongitude == null ||
//         request['latitude'] == null ||
//         request['longitude'] == null) {
//       return null;
//     }

//     return _calculateDistance(
//       businessLatitude!,
//       businessLongitude!,
//       request['latitude'].toDouble(),
//       request['longitude'].toDouble(),
//     );
//   }

//   // Apply filters to job requests
//   // Apply filters to job requests
//   void _applyFilters() {
//     List<dynamic> filtered = List.from(jobRequests);

//     // Filter by status
//     if (_selectedFilter == 'Hired') {
//       filtered = filtered.where((req) => req['is_accepted'] == true).toList();
//     } else if (_selectedFilter == 'Pending') {
//       filtered = filtered.where((req) => req['is_accepted'] == false).toList();
//     }

//     // Filter by distance - FIXED: Include drivers without location data
//     filtered =
//         filtered.where((req) {
//           double? distance = _getDriverDistance(req);
//           // Include drivers without location data OR within distance limit
//           return distance == null || distance <= _maxDistance;
//         }).toList();

//     // Filter by rating - FIXED: Handle null ratings properly
//     filtered =
//         filtered.where((req) {
//           double rating = (req['average_rating'] ?? 0.0).toDouble();
//           return rating >= _minRating;
//         }).toList();

//     // Sort by distance (closest first) - FIXED: Handle null distances
//     filtered.sort((a, b) {
//       double? distanceA = _getDriverDistance(a);
//       double? distanceB = _getDriverDistance(b);

//       if (distanceA == null && distanceB == null) return 0;
//       if (distanceA == null)
//         return 1; // Put drivers without location at the end
//       if (distanceB == null) return -1;

//       return distanceA.compareTo(distanceB);
//     });

//     setState(() {
//       filteredJobRequests = filtered;
//     });
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

//   // Helper method to format rating display
//   Widget _buildRatingDisplay(double rating) {
//     return Row(
//       children: [
//         const Icon(Icons.star, color: Colors.amber, size: 16),
//         const SizedBox(width: 4),
//         Text(
//           rating > 0 ? rating.toStringAsFixed(1) : 'No rating',
//           style: TextStyle(
//             color: rating > 0 ? Colors.black87 : Colors.grey,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   // Helper method to format distance display
//   Widget _buildDistanceDisplay(double? distance) {
//     if (distance == null) {
//       return const Text(
//         'Distance: Unknown',
//         style: TextStyle(fontSize: 13, color: Colors.grey),
//       );
//     }

//     return Row(
//       children: [
//         const Icon(Icons.location_on, size: 16, color: Colors.blue),
//         const SizedBox(width: 4),
//         Text(
//           '${distance.toStringAsFixed(1)} miles away',
//           style: const TextStyle(
//             fontSize: 13,
//             color: Colors.blue,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   // Build filter section
//   Widget _buildFilterSection() {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Filters',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),

//             // Status filter
//             Row(
//               children: [
//                 const Text('Status: '),
//                 const SizedBox(width: 8),
//                 DropdownButton<String>(
//                   value: _selectedFilter,
//                   items:
//                       ['All', 'Hired', 'Pending'].map((String value) {
//                         return DropdownMenuItem<String>(
//                           value: value,
//                           child: Text(value),
//                         );
//                       }).toList(),
//                   onChanged: (String? newValue) {
//                     setState(() {
//                       _selectedFilter = newValue!;
//                       _applyFilters();
//                     });
//                   },
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Distance filter
//             Text('Max Distance: ${_maxDistance.toInt()} miles'),
//             Slider(
//               value: _maxDistance,
//               min: 1,
//               max: 100,
//               divisions: 99,
//               onChanged: (double value) {
//                 setState(() {
//                   _maxDistance = value;
//                   _applyFilters();
//                 });
//               },
//             ),
//             const SizedBox(height: 8),

//             // Rating filter
//             Text('Min Rating: ${_minRating.toStringAsFixed(1)}'),
//             Slider(
//               value: _minRating,
//               min: 0,
//               max: 5,
//               divisions: 50,
//               onChanged: (double value) {
//                 setState(() {
//                   _minRating = value;
//                   _applyFilters();
//                 });
//               },
//             ),
//           ],
//         ),
//       ),
//     );
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
//                     const SizedBox(height: 20),
//                     Text(
//                       "Title: ${jobData!['title']}",
//                       style: const TextStyle(fontSize: 20),
//                     ),
//                     const SizedBox(height: 8),
//                     Text("Description: ${jobData!['description']}"),
//                     const SizedBox(height: 8),
//                     Text(
//                       "Business Name: ${jobData!['business_detail']?['name'] ?? 'Unknown Business'}",
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "Business Address: ${jobData!['business_detail']?['address'] ?? 'Address not available'}",
//                     ),
//                     const SizedBox(height: 8),
//                     Text("Hourly Rate: \$${jobData!['hourly_rate']}"),
//                     const SizedBox(height: 8),
//                     Text(
//                       "Per Delivery Rate: \$${jobData!['per_delivery_rate']}",
//                     ),
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

//                     // Filter section
//                     _buildFilterSection(),

//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           "Applied Members:",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         ),
//                         Text(
//                           "${filteredJobRequests.length} of ${jobRequests.length}",
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),

//                     filteredJobRequests.isEmpty
//                         ? const Text("No drivers match your criteria.")
//                         : Column(
//                           children:
//                               filteredJobRequests.map<Widget>((req) {
//                                 final bool isAccepted = req['is_accepted'];
//                                 final int jobRequestId = req['job_request_id'];
//                                 final int driverId = req['driver_id'];
//                                 final String driverName =
//                                     req['driver_name'] ?? 'Unknown Driver';
//                                 final double averageRating =
//                                     (req['average_rating'] ?? 0.0).toDouble();
//                                 final String preferredAddress =
//                                     req['preferred_working_address'] ??
//                                     'Address not provided';
//                                 final double? distance = _getDriverDistance(
//                                   req,
//                                 );

//                                 return Card(
//                                   margin: const EdgeInsets.symmetric(
//                                     vertical: 8,
//                                   ),
//                                   child: ListTile(
//                                     leading: CircleAvatar(
//                                       backgroundColor:
//                                           isAccepted
//                                               ? Colors.green
//                                               : Colors.blue,
//                                       child: Icon(
//                                         isAccepted ? Icons.check : Icons.person,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                     title: Text("Name: $driverName"),
//                                     subtitle: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text("Driver ID: $driverId"),
//                                         Text("Job Request ID: $jobRequestId"),
//                                         const SizedBox(height: 4),

//                                         // Display Rating
//                                         Row(
//                                           children: [
//                                             const Text("Rating: "),
//                                             _buildRatingDisplay(averageRating),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 4),

//                                         // Display Distance
//                                         _buildDistanceDisplay(distance),
//                                         const SizedBox(height: 4),

//                                         // Display Preferred Address
//                                         Text(
//                                           "Address: $preferredAddress",
//                                           style: const TextStyle(fontSize: 13),
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),

//                                         const SizedBox(height: 8),
//                                         isAccepted
//                                             ? Row(
//                                               children: [
//                                                 Container(
//                                                   padding:
//                                                       const EdgeInsets.symmetric(
//                                                         horizontal: 8,
//                                                         vertical: 4,
//                                                       ),
//                                                   decoration: BoxDecoration(
//                                                     color:
//                                                         Colors.green.shade100,
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           12,
//                                                         ),
//                                                   ),
//                                                   child: const Text(
//                                                     "Hired",
//                                                     style: TextStyle(
//                                                       color: Colors.green,
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 const SizedBox(width: 16),
//                                                 ElevatedButton.icon(
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
//                                                             ),
//                                                       ),
//                                                     );
//                                                   },
//                                                   icon: const Icon(Icons.chat),
//                                                   label: const Text("Chat"),
//                                                 ),
//                                               ],
//                                             )
//                                             : ElevatedButton.icon(
//                                               onPressed: () async {
//                                                 await _hireDriver(jobRequestId);
//                                               },
//                                               icon: const Icon(Icons.work),
//                                               label: const Text("Hire"),
//                                               style: ElevatedButton.styleFrom(
//                                                 backgroundColor: Colors.blue,
//                                                 foregroundColor: Colors.white,
//                                               ),
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

// with ui blue page good page with applied members

// import 'dart:convert';
// import 'dart:math';
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
//   List<dynamic> filteredJobRequests = [];
//   String? _authToken;

//   // Business location data
//   double? businessLatitude;
//   double? businessLongitude;

//   // Filter variables
//   String _selectedFilter = 'All';
//   double _maxDistance = 50.0;
//   double _minRating = 0.0;
//   bool _isFilterVisible = false;

//   // Blue theme colors
//   static const Color primaryBlue = Color(0xFF1565C0);
//   static const Color lightBlue = Color(0xFF42A5F5);
//   static const Color darkBlue = Color(0xFF0D47A1);
//   static const Color accentBlue = Color(0xFF64B5F6);
//   static const Color backgroundBlue = Color(0xFFF3F8FF);

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

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           jobData = data;
//           if (data['business_detail'] != null) {
//             businessLatitude = data['business_detail']['latitude']?.toDouble();
//             businessLongitude =
//                 data['business_detail']['longitude']?.toDouble();
//           }
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
//       request.headers.addAll({'Authorization': 'Bearer $_authToken'});

//       http.StreamedResponse response = await request.send();

//       if (response.statusCode == 200) {
//         String responseBody = await response.stream.bytesToString();
//         final List<dynamic> requestData = json.decode(responseBody);
//         setState(() {
//           jobRequests = requestData;
//           _applyFilters();
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

//   double _calculateDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const double earthRadius = 3959;
//     double dLat = _degreesToRadians(lat2 - lat1);
//     double dLon = _degreesToRadians(lon2 - lon1);
//     double a =
//         sin(dLat / 2) * sin(dLat / 2) +
//         cos(_degreesToRadians(lat1)) *
//             cos(_degreesToRadians(lat2)) *
//             sin(dLon / 2) *
//             sin(dLon / 2);
//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return earthRadius * c;
//   }

//   double _degreesToRadians(double degrees) {
//     return degrees * (pi / 180);
//   }

//   double? _getDriverDistance(Map<String, dynamic> request) {
//     if (businessLatitude == null ||
//         businessLongitude == null ||
//         request['latitude'] == null ||
//         request['longitude'] == null) {
//       return null;
//     }
//     return _calculateDistance(
//       businessLatitude!,
//       businessLongitude!,
//       request['latitude'].toDouble(),
//       request['longitude'].toDouble(),
//     );
//   }

//   void _applyFilters() {
//     List<dynamic> filtered = List.from(jobRequests);

//     if (_selectedFilter == 'Accepted') {
//       filtered = filtered.where((req) => req['status'] == 'accepted').toList();
//     } else if (_selectedFilter == 'Pending') {
//       filtered = filtered.where((req) => req['status'] == 'pending').toList();
//     }

//     filtered =
//         filtered.where((req) {
//           double? distance = _getDriverDistance(req);
//           return distance == null || distance <= _maxDistance;
//         }).toList();

//     filtered =
//         filtered.where((req) {
//           double rating = (req['average_rating'] ?? 0.0).toDouble();
//           return rating >= _minRating;
//         }).toList();

//     filtered.sort((a, b) {
//       double? distanceA = _getDriverDistance(a);
//       double? distanceB = _getDriverDistance(b);
//       if (distanceA == null && distanceB == null) return 0;
//       if (distanceA == null) return 1;
//       if (distanceB == null) return -1;
//       return distanceA.compareTo(distanceB);
//     });

//     setState(() {
//       filteredJobRequests = filtered;
//     });
//   }

//   Future<void> _hireDriver(int jobRequestId) async {
//     final url = Uri.parse('$baseUrl/api/job-requests/$jobRequestId/accept/');
//     try {
//       final response = await http.post(
//         url,
//         headers: _getAuthHeaders(),
//         body: json.encode({}),
//       );
//       if (response.statusCode == 200) {
//         await fetchJobDetails();
//         await fetchJobRequests();
//       }
//     } catch (e) {
//       print('Hire Error: $e');
//     }
//   }

//   Future<void> _cancelJobRequest(int jobRequestId) async {
//     final url = Uri.parse(
//       '$baseUrl/api/job-request/$jobRequestId/cancel-by-shopkeeper/',
//     );
//     try {
//       final response = await http.post(
//         url,
//         headers: _getAuthHeaders(),
//         body: json.encode({}),
//       );
//       if (response.statusCode == 200) {
//         await fetchJobRequests();
//       } else {
//         print('Cancel Error: ${response.reasonPhrase}');
//       }
//     } catch (e) {
//       print('Cancel Exception: $e');
//     }
//   }

//   Widget _buildRatingDisplay(double rating) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color:
//             rating > 0
//                 ? accentBlue.withOpacity(0.1)
//                 : Colors.grey.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.star,
//             color: rating > 0 ? Colors.amber : Colors.grey,
//             size: 14,
//           ),
//           const SizedBox(width: 2),
//           Text(
//             rating > 0 ? rating.toStringAsFixed(1) : 'No rating',
//             style: TextStyle(
//               color: rating > 0 ? darkBlue : Colors.grey,
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDistanceDisplay(double? distance) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: lightBlue.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.location_on, size: 14, color: primaryBlue),
//           const SizedBox(width: 2),
//           Text(
//             distance != null ? '${distance.toStringAsFixed(1)} mi' : 'Unknown',
//             style: TextStyle(
//               fontSize: 12,
//               color: primaryBlue,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoCard() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [primaryBlue, lightBlue],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: primaryBlue.withOpacity(0.3),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               jobData!['title'],
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               jobData!['description'],
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.white.withOpacity(0.9),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildRateChip(
//                     '\$${jobData!['hourly_rate']}/hr',
//                     Icons.schedule,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _buildRateChip(
//                     '\$${jobData!['per_delivery_rate']}/del',
//                     Icons.local_shipping,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             _buildTimeChip(
//               '${jobData!['start_time']} - ${jobData!['end_time']}',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRateChip(String text, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: Colors.white),
//           const SizedBox(width: 4),
//           Text(
//             text,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimeChip(String time) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.access_time, size: 16, color: Colors.white),
//           const SizedBox(width: 4),
//           Text(
//             time,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBusinessCard() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: accentBlue.withOpacity(0.3)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: primaryBlue.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(Icons.business, color: primaryBlue, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       jobData!['business_detail']?['name'] ??
//                           'Unknown Business',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: darkBlue,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       jobData!['business_detail']?['address'] ??
//                           'Address not available',
//                       style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           if (jobData!['complimentary_benefits'] != null &&
//               (jobData!['complimentary_benefits'] as List).isNotEmpty) ...[
//             const SizedBox(height: 12),
//             Text(
//               'Benefits:',
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: darkBlue,
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Wrap(
//               spacing: 6,
//               runSpacing: 4,
//               children:
//                   (jobData!['complimentary_benefits'] as List)
//                       .map(
//                         (benefit) => Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: accentBlue.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             benefit.toString(),
//                             style: TextStyle(
//                               fontSize: 11,
//                               color: primaryBlue,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterSection() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       height: _isFilterVisible ? null : 0,
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: _isFilterVisible ? const EdgeInsets.all(16) : EdgeInsets.zero,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: accentBlue.withOpacity(0.3)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child:
//           _isFilterVisible
//               ? SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.filter_list,
//                               color: primaryBlue,
//                               size: 20,
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               'Filters',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: darkBlue,
//                               ),
//                             ),
//                           ],
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.close, color: primaryBlue, size: 20),
//                           onPressed: () {
//                             setState(() {
//                               _isFilterVisible = false;
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Text(
//                           'Status: ',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w500,
//                             color: darkBlue,
//                             fontSize: 14,
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: backgroundBlue,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: DropdownButton<String>(
//                             value: _selectedFilter,
//                             underline: const SizedBox(),
//                             style: TextStyle(color: primaryBlue, fontSize: 14),
//                             items:
//                                 ['All', 'Accepted', 'Pending'].map((
//                                   String value,
//                                 ) {
//                                   return DropdownMenuItem<String>(
//                                     value: value,
//                                     child: Text(value),
//                                   );
//                                 }).toList(),
//                             onChanged: (String? newValue) {
//                               setState(() {
//                                 _selectedFilter = newValue!;
//                                 _applyFilters();
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Max Distance: ${_maxDistance.toInt()} miles',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w500,
//                         color: darkBlue,
//                         fontSize: 14,
//                       ),
//                     ),
//                     SliderTheme(
//                       data: SliderTheme.of(context).copyWith(
//                         activeTrackColor: primaryBlue,
//                         inactiveTrackColor: accentBlue.withOpacity(0.3),
//                         thumbColor: primaryBlue,
//                         overlayColor: primaryBlue.withOpacity(0.2),
//                       ),
//                       child: Slider(
//                         value: _maxDistance,
//                         min: 1,
//                         max: 100,
//                         divisions: 99,
//                         onChanged: (double value) {
//                           setState(() {
//                             _maxDistance = value;
//                             _applyFilters();
//                           });
//                         },
//                       ),
//                     ),
//                     Text(
//                       'Min Rating: ${_minRating.toStringAsFixed(1)}',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w500,
//                         color: darkBlue,
//                         fontSize: 14,
//                       ),
//                     ),
//                     SliderTheme(
//                       data: SliderTheme.of(context).copyWith(
//                         activeTrackColor: primaryBlue,
//                         inactiveTrackColor: accentBlue.withOpacity(0.3),
//                         thumbColor: primaryBlue,
//                         overlayColor: primaryBlue.withOpacity(0.2),
//                       ),
//                       child: Slider(
//                         value: _minRating,
//                         min: 0,
//                         max: 5,
//                         divisions: 50,
//                         onChanged: (double value) {
//                           setState(() {
//                             _minRating = value;
//                             _applyFilters();
//                           });
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//               : const SizedBox.shrink(),
//     );
//   }

//   Widget _buildDriverCard(Map<String, dynamic> req) {
//     final bool isAccepted = req['status'] == 'accepted';
//     final bool isCancelled =
//         req['status'] == 'cancelled_by_shopkeeper' ||
//         req['status'] == 'cancelled_by_driver';
//     final int jobRequestId = req['job_request_id'];
//     final int driverId = req['driver_id'];
//     final String driverName = req['driver_name'] ?? 'Unknown Driver';
//     final double averageRating = (req['average_rating'] ?? 0.0).toDouble();
//     final String preferredAddress =
//         req['preferred_working_address'] ?? 'Address not provided';
//     final double? distance = _getDriverDistance(req);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color:
//               isAccepted
//                   ? Colors.green.withOpacity(0.3)
//                   : isCancelled
//                   ? Colors.red.withOpacity(0.3)
//                   : accentBlue.withOpacity(0.3),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color:
//                         isAccepted
//                             ? Colors.green.withOpacity(0.1)
//                             : isCancelled
//                             ? Colors.red.withOpacity(0.1)
//                             : primaryBlue.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     isAccepted
//                         ? Icons.check_circle
//                         : isCancelled
//                         ? Icons.cancel
//                         : Icons.person,
//                     color:
//                         isAccepted
//                             ? Colors.green
//                             : isCancelled
//                             ? Colors.red
//                             : primaryBlue,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         driverName,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: darkBlue,
//                         ),
//                       ),
//                       Text(
//                         'ID: $driverId',
//                         style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (isAccepted)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.green.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Text(
//                       'HIRED',
//                       style: TextStyle(
//                         color: Colors.green,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 11,
//                       ),
//                     ),
//                   )
//                 else if (isCancelled)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.red.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       req['status'] == 'cancelled_by_shopkeeper'
//                           ? 'CANCELLED BY YOU'
//                           : 'CANCELLED BY DRIVER',
//                       style: const TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 _buildRatingDisplay(averageRating),
//                 const SizedBox(width: 8),
//                 _buildDistanceDisplay(distance),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               preferredAddress,
//               style: TextStyle(fontSize: 13, color: Colors.grey[700]),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 if (isAccepted)
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (context) =>
//                                     ChatScreen(jobRequestId: jobRequestId),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.chat, size: 18),
//                       label: const Text('Chat'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryBlue,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   )
//                 else if (!isCancelled)
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () async {
//                         await _hireDriver(jobRequestId);
//                       },
//                       icon: const Icon(Icons.work, size: 18),
//                       label: const Text('Hire Driver'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryBlue,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 if (!isCancelled) ...[
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () async {
//                         await _cancelJobRequest(jobRequestId);
//                       },
//                       icon: const Icon(Icons.cancel, size: 18),
//                       label: const Text('Cancel'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundBlue,
//       appBar: AppBar(
//         title: const Text(
//           'Job Details',
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         backgroundColor: primaryBlue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             _isFilterVisible = !_isFilterVisible;
//           });
//         },
//         backgroundColor: primaryBlue,
//         child: Icon(
//           _isFilterVisible ? Icons.filter_alt_off : Icons.filter_alt,
//           color: Colors.white,
//         ),
//       ),
//       body:
//           _isLoading
//               ? Center(
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
//                 ),
//               )
//               : _errorMessage != null
//               ? Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Text(
//                     _errorMessage!,
//                     style: const TextStyle(color: Colors.red, fontSize: 16),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               )
//               : jobData == null
//               ? const Center(child: Text("Failed to load data"))
//               : SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildInfoCard(),
//                     _buildBusinessCard(),
//                     if (_isFilterVisible) _buildFilterSection(),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 4,
//                         vertical: 8,
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Applied Drivers',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: darkBlue,
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: primaryBlue.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               '${filteredJobRequests.length}/${jobRequests.length}',
//                               style: TextStyle(
//                                 color: primaryBlue,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (filteredJobRequests.isEmpty)
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(32),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Column(
//                           children: [
//                             Icon(
//                               Icons.search_off,
//                               size: 48,
//                               color: Colors.grey[400],
//                             ),
//                             const SizedBox(height: 12),
//                             Text(
//                               'No drivers match your criteria',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                     else
//                       ...filteredJobRequests.map(
//                         (req) => _buildDriverCard(req),
//                       ),
//                   ],
//                 ),
//               ),
//     );
//   }
// }


// without UI Code ---------------------------------------------

// import 'dart:convert';
// import 'dart:math';
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
//   List<dynamic> filteredJobRequests = [];
//   String? _authToken;

//   // Business location data
//   double? businessLatitude;
//   double? businessLongitude;

//   // Filter variables
//   String _selectedFilter = 'All';
//   double _maxDistance = 50.0;
//   double _minRating = 0.0;
//   bool _isFilterVisible = false;

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

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           jobData = data;
//           if (data['business_detail'] != null) {
//             businessLatitude = data['business_detail']['latitude']?.toDouble();
//             businessLongitude =
//                 data['business_detail']['longitude']?.toDouble();
//           }
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
//       request.headers.addAll({'Authorization': 'Bearer $_authToken'});

//       http.StreamedResponse response = await request.send();

//       if (response.statusCode == 200) {
//         String responseBody = await response.stream.bytesToString();
//         final List<dynamic> requestData = json.decode(responseBody);
//         setState(() {
//           jobRequests = requestData;
//           _applyFilters();
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

//   double _calculateDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const double earthRadius = 3959;
//     double dLat = _degreesToRadians(lat2 - lat1);
//     double dLon = _degreesToRadians(lon2 - lon1);
//     double a =
//         sin(dLat / 2) * sin(dLat / 2) +
//         cos(_degreesToRadians(lat1)) *
//             cos(_degreesToRadians(lat2)) *
//             sin(dLon / 2) *
//             sin(dLon / 2);
//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return earthRadius * c;
//   }

//   double _degreesToRadians(double degrees) {
//     return degrees * (pi / 180);
//   }

//   double? _getDriverDistance(Map<String, dynamic> request) {
//     if (businessLatitude == null ||
//         businessLongitude == null ||
//         request['latitude'] == null ||
//         request['longitude'] == null) {
//       return null;
//     }
//     return _calculateDistance(
//       businessLatitude!,
//       businessLongitude!,
//       request['latitude'].toDouble(),
//       request['longitude'].toDouble(),
//     );
//   }

//   void _applyFilters() {
//     List<dynamic> filtered = List.from(jobRequests);

//     if (_selectedFilter == 'Accepted') {
//       filtered = filtered.where((req) => req['status'] == 'accepted').toList();
//     } else if (_selectedFilter == 'Pending') {
//       filtered = filtered.where((req) => req['status'] == 'pending').toList();
//     }

//     filtered =
//         filtered.where((req) {
//           double? distance = _getDriverDistance(req);
//           return distance == null || distance <= _maxDistance;
//         }).toList();

//     filtered =
//         filtered.where((req) {
//           double rating = (req['average_rating'] ?? 0.0).toDouble();
//           return rating >= _minRating;
//         }).toList();

//     filtered.sort((a, b) {
//       double? distanceA = _getDriverDistance(a);
//       double? distanceB = _getDriverDistance(b);
//       if (distanceA == null && distanceB == null) return 0;
//       if (distanceA == null) return 1;
//       if (distanceB == null) return -1;
//       return distanceA.compareTo(distanceB);
//     });

//     setState(() {
//       filteredJobRequests = filtered;
//     });
//   }

//   Future<void> _hireDriver(int jobRequestId) async {
//     final url = Uri.parse('$baseUrl/api/job-requests/$jobRequestId/accept/');
//     try {
//       final response = await http.post(
//         url,
//         headers: _getAuthHeaders(),
//         body: json.encode({}),
//       );
//       if (response.statusCode == 200) {
//         await fetchJobDetails();
//         await fetchJobRequests();
//       }
//     } catch (e) {
//       print('Hire Error: $e');
//     }
//   }

//   Future<void> _cancelJobRequest(int jobRequestId) async {
//     final url = Uri.parse(
//       '$baseUrl/api/job-request/$jobRequestId/cancel-by-shopkeeper/',
//     );
//     try {
//       final response = await http.post(
//         url,
//         headers: _getAuthHeaders(),
//         body: json.encode({}),
//       );
//       if (response.statusCode == 200) {
//         await fetchJobRequests();
//       } else {
//         print('Cancel Error: ${response.reasonPhrase}');
//       }
//     } catch (e) {
//       print('Cancel Exception: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Job Details')),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             _isFilterVisible = !_isFilterVisible;
//           });
//         },
//         child: Icon(_isFilterVisible ? Icons.filter_alt_off : Icons.filter_alt),
//       ),
//       body:
//           _isLoading
//               ? Center(child: CircularProgressIndicator())
//               : _errorMessage != null
//               ? Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Text(
//                     _errorMessage!,
//                     style: TextStyle(color: Colors.red, fontSize: 16),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               )
//               : jobData == null
//               ? Center(child: Text("Failed to load data"))
//               : SingleChildScrollView(
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Job Info Card
//                     Card(
//                       child: Padding(
//                         padding: EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               jobData!['title'],
//                               style: TextStyle(
//                                 fontSize: 22,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             SizedBox(height: 8),
//                             Text(jobData!['description']),
//                             SizedBox(height: 12),
//                             Text(
//                               'Hourly Rate: \$${jobData!['hourly_rate']}/hr',
//                             ),
//                             Text(
//                               'Per Delivery: \$${jobData!['per_delivery_rate']}/del',
//                             ),
//                             Text(
//                               'Time: ${jobData!['start_time']} - ${jobData!['end_time']}',
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 12),

//                     // Business Card
//                     Card(
//                       child: Padding(
//                         padding: EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Business: ${jobData!['business_detail']?['name'] ?? 'Unknown Business'}',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               'Address: ${jobData!['business_detail']?['address'] ?? 'Address not available'}',
//                             ),
//                             if (jobData!['complimentary_benefits'] != null &&
//                                 (jobData!['complimentary_benefits'] as List)
//                                     .isNotEmpty) ...[
//                               SizedBox(height: 8),
//                               Text(
//                                 'Benefits: ${(jobData!['complimentary_benefits'] as List).join(', ')}',
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 12),

//                     // Filter Section
//                     if (_isFilterVisible)
//                       Card(
//                         child: Padding(
//                           padding: EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Filters',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               SizedBox(height: 12),
//                               Row(
//                                 children: [
//                                   Text('Status: '),
//                                   DropdownButton<String>(
//                                     value: _selectedFilter,
//                                     items:
//                                         ['All', 'Accepted', 'Pending'].map((
//                                           String value,
//                                         ) {
//                                           return DropdownMenuItem<String>(
//                                             value: value,
//                                             child: Text(value),
//                                           );
//                                         }).toList(),
//                                     onChanged: (String? newValue) {
//                                       setState(() {
//                                         _selectedFilter = newValue!;
//                                         _applyFilters();
//                                       });
//                                     },
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: 12),
//                               Text(
//                                 'Max Distance: ${_maxDistance.toInt()} miles',
//                               ),
//                               Slider(
//                                 value: _maxDistance,
//                                 min: 1,
//                                 max: 100,
//                                 divisions: 99,
//                                 onChanged: (double value) {
//                                   setState(() {
//                                     _maxDistance = value;
//                                     _applyFilters();
//                                   });
//                                 },
//                               ),
//                               Text(
//                                 'Min Rating: ${_minRating.toStringAsFixed(1)}',
//                               ),
//                               Slider(
//                                 value: _minRating,
//                                 min: 0,
//                                 max: 5,
//                                 divisions: 50,
//                                 onChanged: (double value) {
//                                   setState(() {
//                                     _minRating = value;
//                                     _applyFilters();
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                     // Applied Drivers Header
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Applied Drivers',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           '${filteredJobRequests.length}/${jobRequests.length}',
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 16),

//                     // Drivers List
//                     if (filteredJobRequests.isEmpty)
//                       Card(
//                         child: Padding(
//                           padding: EdgeInsets.all(32),
//                           child: Center(
//                             child: Column(
//                               children: [
//                                 Icon(
//                                   Icons.search_off,
//                                   size: 48,
//                                   color: Colors.grey,
//                                 ),
//                                 SizedBox(height: 12),
//                                 Text('No drivers match your criteria'),
//                               ],
//                             ),
//                           ),
//                         ),
//                       )
//                     else
//                       ...filteredJobRequests.map((req) {
//                         final bool isAccepted = req['status'] == 'accepted';
//                         final bool isCancelled =
//                             req['status'] == 'cancelled_by_shopkeeper' ||
//                             req['status'] == 'cancelled_by_driver';
//                         final int jobRequestId = req['job_request_id'];
//                         final int driverId = req['driver_id'];
//                         final String driverName =
//                             req['driver_name'] ?? 'Unknown Driver';
//                         final double averageRating =
//                             (req['average_rating'] ?? 0.0).toDouble();
//                         final String preferredAddress =
//                             req['preferred_working_address'] ??
//                             'Address not provided';
//                         final double? distance = _getDriverDistance(req);

//                         return Card(
//                           margin: EdgeInsets.only(bottom: 12),
//                           child: Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             driverName,
//                                             style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                           Text('ID: $driverId'),
//                                         ],
//                                       ),
//                                     ),
//                                     if (isAccepted)
//                                       Container(
//                                         padding: EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 4,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.green,
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           'HIRED',
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 11,
//                                           ),
//                                         ),
//                                       )
//                                     else if (isCancelled)
//                                       Container(
//                                         padding: EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 4,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.red,
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           req['status'] ==
//                                                   'cancelled_by_shopkeeper'
//                                               ? 'CANCELLED BY YOU'
//                                               : 'CANCELLED BY DRIVER',
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 11,
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 8),
//                                 Text(
//                                   'Rating: ${averageRating > 0 ? averageRating.toStringAsFixed(1) : 'No rating'}',
//                                 ),
//                                 if (distance != null)
//                                   Text(
//                                     'Distance: ${distance.toStringAsFixed(1)} mi',
//                                   ),
//                                 Text(
//                                   'Address: $preferredAddress',
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 SizedBox(height: 12),
//                                 if (isAccepted)
//                                   SizedBox(
//                                     width: double.infinity,
//                                     child: ElevatedButton.icon(
//                                       onPressed: () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder:
//                                                 (context) => ChatScreen(
//                                                   jobRequestId: jobRequestId,
//                                                 ),
//                                           ),
//                                         );
//                                       },
//                                       icon: Icon(Icons.chat),
//                                       label: Text('Chat'),
//                                     ),
//                                   )
//                                 else if (!isCancelled)
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: ElevatedButton.icon(
//                                           onPressed: () async {
//                                             await _hireDriver(jobRequestId);
//                                           },
//                                           icon: Icon(Icons.work),
//                                           label: Text('Hire Driver'),
//                                         ),
//                                       ),
//                                       SizedBox(width: 8),
//                                       Expanded(
//                                         child: ElevatedButton.icon(
//                                           onPressed: () async {
//                                             await _cancelJobRequest(
//                                               jobRequestId,
//                                             );
//                                           },
//                                           icon: Icon(Icons.cancel),
//                                           label: Text('Cancel'),
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.red,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                   ],
//                 ),
//               ),
//     );
//   }
// }

