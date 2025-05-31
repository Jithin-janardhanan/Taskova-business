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

//   // Helper method to format driving duration
//   String _formatDrivingDuration(String? duration) {
//     if (duration == null || duration.isEmpty) {
//       return 'Not specified';
//     }
//     return duration;
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
//                                 final String driverName =
//                                     req['driver_name'] ?? 'Unknown Driver';
//                                 final double averageRating =
//                                     (req['average_rating'] ?? 0.0).toDouble();
//                                 final String drivingDuration =
//                                     req['Driving_Duration'] ?? '';

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
//                                         const SizedBox(height: 4),

//                                         // Display Rating
//                                         Row(
//                                           children: [
//                                             const Text("Rating: "),
//                                             _buildRatingDisplay(averageRating),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 4),

//                                         // Display Driving Duration
//                                         Text(
//                                           "Driving Duration: ${_formatDrivingDuration(drivingDuration)}",
//                                           style: const TextStyle(fontSize: 13),
//                                         ),

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
import 'dart:math';
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
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? jobData;
  List<dynamic> jobRequests = [];
  List<dynamic> filteredJobRequests = [];
  String? _authToken;

  // Business location data
  double? businessLatitude;
  double? businessLongitude;

  // Filter variables
  String _selectedFilter = 'All';
  double _maxDistance = 50.0; // Default max distance in miles
  double _minRating = 0.0; // Default min rating

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchJobDetails();
  }

  Future<void> _loadTokenAndFetchJobDetails() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('access_token');

    if (_authToken == null) {
      setState(() {
        _errorMessage = "Not logged in.";
        _isLoading = false;
      });
      return;
    }

    await fetchJobDetails();
    await fetchJobRequests();
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchJobDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/job-posts/${widget.jobId}/'),
        headers: _getAuthHeaders(),
      );
      print(
        '($response)*********************************************************',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          jobData = data;
          // Save business coordinates
          if (data['business_detail'] != null) {
            businessLatitude = data['business_detail']['latitude']?.toDouble();
            businessLongitude =
                data['business_detail']['longitude']?.toDouble();
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load job details. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> fetchJobRequests() async {
    try {
      var request = http.Request(
        'GET',
        Uri.parse('$baseUrl/api/job-requests/list/${widget.jobId}'),
      );
      print(
        '($request)*********************************************************',
      );
      request.headers.addAll({'Authorization': 'Bearer $_authToken'});

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        final List<dynamic> requestData = json.decode(responseBody);
        setState(() {
          jobRequests = requestData;
          _applyFilters();
        });
      } else {
        print("Job Requests Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Job Requests Exception: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 3959; // Earth's radius in miles

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Get distance between driver and business
  double? _getDriverDistance(Map<String, dynamic> request) {
    if (businessLatitude == null ||
        businessLongitude == null ||
        request['latitude'] == null ||
        request['longitude'] == null) {
      return null;
    }

    return _calculateDistance(
      businessLatitude!,
      businessLongitude!,
      request['latitude'].toDouble(),
      request['longitude'].toDouble(),
    );
  }

  // Apply filters to job requests
  void _applyFilters() {
    List<dynamic> filtered = List.from(jobRequests);

    // Filter by status
    if (_selectedFilter == 'Hired') {
      filtered = filtered.where((req) => req['is_accepted'] == true).toList();
    } else if (_selectedFilter == 'Pending') {
      filtered = filtered.where((req) => req['is_accepted'] == false).toList();
    }

    // Filter by distance
    filtered =
        filtered.where((req) {
          double? distance = _getDriverDistance(req);
          return distance == null || distance <= _maxDistance;
        }).toList();

    // Filter by rating
    filtered =
        filtered.where((req) {
          double rating = (req['average_rating'] ?? 0.0).toDouble();
          return rating >= _minRating;
        }).toList();

    // Sort by distance (closest first)
    filtered.sort((a, b) {
      double? distanceA = _getDriverDistance(a);
      double? distanceB = _getDriverDistance(b);

      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;

      return distanceA.compareTo(distanceB);
    });

    setState(() {
      filteredJobRequests = filtered;
    });
  }

  Future<void> _hireDriver(int jobRequestId) async {
    final url = Uri.parse('$baseUrl/api/job-requests/$jobRequestId/accept/');

    try {
      final response = await http.post(
        url,
        headers: _getAuthHeaders(),
        body: json.encode({}), // Send empty JSON body
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Hire Success: $responseData');
        await fetchJobRequests(); // Refresh UI
      } else {
        print('Hire Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Hire Error: $e');
    }
  }

  // Helper method to format rating display
  Widget _buildRatingDisplay(double rating) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : 'No rating',
          style: TextStyle(
            color: rating > 0 ? Colors.black87 : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Helper method to format distance display
  Widget _buildDistanceDisplay(double? distance) {
    if (distance == null) {
      return const Text(
        'Distance: Unknown',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      );
    }

    return Row(
      children: [
        const Icon(Icons.location_on, size: 16, color: Colors.blue),
        const SizedBox(width: 4),
        Text(
          '${distance.toStringAsFixed(1)} miles away',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Build filter section
  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Status filter
            Row(
              children: [
                const Text('Status: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items:
                      ['All', 'Hired', 'Pending'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFilter = newValue!;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Distance filter
            Text('Max Distance: ${_maxDistance.toInt()} miles'),
            Slider(
              value: _maxDistance,
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (double value) {
                setState(() {
                  _maxDistance = value;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(height: 8),

            // Rating filter
            Text('Min Rating: ${_minRating.toStringAsFixed(1)}'),
            Slider(
              value: _minRating,
              min: 0,
              max: 5,
              divisions: 50,
              onChanged: (double value) {
                setState(() {
                  _minRating = value;
                  _applyFilters();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Post Details')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : jobData == null
              ? const Center(child: Text("Failed to load data"))
              : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Title: ${jobData!['title']}",
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text("Description: ${jobData!['description']}"),
                    const SizedBox(height: 8),
                    Text(
                      "Business Name: ${jobData!['business_detail']?['name'] ?? 'Unknown Business'}",
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Business Address: ${jobData!['business_detail']?['address'] ?? 'Address not available'}",
                    ),
                    const SizedBox(height: 8),
                    Text("Hourly Rate: \$${jobData!['hourly_rate']}"),
                    const SizedBox(height: 8),
                    Text(
                      "Per Delivery Rate: \$${jobData!['per_delivery_rate']}",
                    ),
                    const SizedBox(height: 8),
                    Text("Start Time: ${jobData!['start_time']}"),
                    const SizedBox(height: 8),
                    Text("End Time: ${jobData!['end_time']}"),
                    const SizedBox(height: 8),

                    const Text(
                      "Complimentary Benefits:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (jobData!['complimentary_benefits'] != null)
                      ...List<Widget>.from(
                        (jobData!['complimentary_benefits'] as List).map(
                          (item) => Text("• $item"),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Filter section
                    _buildFilterSection(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Applied Members:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "${filteredJobRequests.length} of ${jobRequests.length}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    filteredJobRequests.isEmpty
                        ? const Text("No drivers match your criteria.")
                        : Column(
                          children:
                              filteredJobRequests.map<Widget>((req) {
                                final bool isAccepted = req['is_accepted'];
                                final int jobRequestId = req['job_request_id'];
                                final int driverId = req['driver_id'];
                                final String driverName =
                                    req['driver_name'] ?? 'Unknown Driver';
                                final double averageRating =
                                    (req['average_rating'] ?? 0.0).toDouble();
                                final String preferredAddress =
                                    req['preferred_working_address'] ??
                                    'Address not provided';
                                final double? distance = _getDriverDistance(
                                  req,
                                );

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          isAccepted
                                              ? Colors.green
                                              : Colors.blue,
                                      child: Icon(
                                        isAccepted ? Icons.check : Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text("Name: $driverName"),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Driver ID: $driverId"),
                                        Text("Job Request ID: $jobRequestId"),
                                        const SizedBox(height: 4),

                                        // Display Rating
                                        Row(
                                          children: [
                                            const Text("Rating: "),
                                            _buildRatingDisplay(averageRating),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Display Distance
                                        _buildDistanceDisplay(distance),
                                        const SizedBox(height: 4),

                                        // Display Preferred Address
                                        Text(
                                          "Address: $preferredAddress",
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 8),
                                        isAccepted
                                            ? Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    "Hired",
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => ChatScreen(
                                                              jobRequestId:
                                                                  jobRequestId,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.chat),
                                                  label: const Text("Chat"),
                                                ),
                                              ],
                                            )
                                            : ElevatedButton.icon(
                                              onPressed: () async {
                                                await _hireDriver(jobRequestId);
                                              },
                                              icon: const Icon(Icons.work),
                                              label: const Text("Hire"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                  ],
                ),
              ),
    );
  }
}
