// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_shopkeeper/Model/api_config.dart';

// class ExpiredJobsContent extends StatefulWidget {
//   const ExpiredJobsContent({Key? key}) : super(key: key);

//   @override
//   State<ExpiredJobsContent> createState() => _ExpiredJobsContentState();
// }

// class _ExpiredJobsContentState extends State<ExpiredJobsContent> {
//   // Variables for expired jobs
//   List<dynamic> _expiredJobsList = [];
//   bool _isLoadingExpiredJobs = false;
//   String? _errorMessage;
//   String? _authToken;

//   @override
//   void initState() {
//     super.initState();
//     loadTokenAndFetchExpiredJobs();
//   }

//   // Load authentication token from SharedPreferences
//   Future<void> _loadToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _authToken = prefs.getString(
//         'access_token',
//       ); // Or whatever your actual key is
//     });
//   }

//   // Get authorization headers
//   Map<String, String> _getAuthHeaders() {
//     return {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $_authToken',
//     };
//   }

//   // Fetch expired/archived jobs
//   Future<void> fetchExpiredJobs() async {
//     setState(() {
//       _isLoadingExpiredJobs = true;
//       _errorMessage = null;
//     });

//     try {
//       // Replace with your actual API endpoint
//       final response = await http.get(
//         Uri.parse(
//           '${ApiConfig.baseUrl}/api/jobs/archived/',
//         ), // Adjust baseUrl as needed
//         headers: _getAuthHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> expiredJobs = json.decode(response.body);

//         setState(() {
//           _expiredJobsList = expiredJobs;
//           _isLoadingExpiredJobs = false;
//         });
//         print('Fetched ${expiredJobs.length} expired jobs');
//       } else {
//         setState(() {
//           _errorMessage =
//               'Failed to fetch expired jobs: ${response.statusCode}';
//           _isLoadingExpiredJobs = false;
//         });
//         print('Error: ${response.reasonPhrase}');
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error fetching expired jobs: ${e.toString()}';
//         _isLoadingExpiredJobs = false;
//       });
//       print('Exception: $e');
//     }
//   }

//   // Load token and fetch expired jobs
//   Future<void> loadTokenAndFetchExpiredJobs() async {
//     try {
//       await _loadToken();
//       if (_authToken != null) {
//         await fetchExpiredJobs();
//       } else {
//         setState(() {
//           _errorMessage = 'No authentication token found. Please login again.';
//           _isLoadingExpiredJobs = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'An error occurred: ${e.toString()}';
//         _isLoadingExpiredJobs = false;
//       });
//     }
//   }

//   // Widget to display expired jobs
//   Widget buildExpiredJobsList() {
//     if (_isLoadingExpiredJobs) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_errorMessage != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
//             const SizedBox(height: 16),
//             Text(
//               _errorMessage!,
//               style: const TextStyle(color: Colors.red),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: loadTokenAndFetchExpiredJobs,
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_expiredJobsList.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
//             const SizedBox(height: 16),
//             const Text(
//               'No expired jobs found',
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: fetchExpiredJobs,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(8.0),
//         itemCount: _expiredJobsList.length,
//         itemBuilder: (context, index) {
//           final job = _expiredJobsList[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
//             elevation: 2,
//             child: ListTile(
//               contentPadding: const EdgeInsets.all(16.0),
//               title: Text(
//                 job['title'] ?? 'No Title',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 8),
//                   Text(
//                     job['description'] ?? 'No Description',
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Date: ${job['job_date'] ?? 'N/A'}',
//                     style: TextStyle(color: Colors.grey.shade600),
//                   ),
//                   Text(
//                     'Rate: £${job['hourly_rate'] ?? '0'}/hr',
//                     style: TextStyle(
//                       color: Colors.green.shade700,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (job['business_detail'] != null)
//                     Text(
//                       'Business: ${job['business_detail']['name'] ?? 'N/A'}',
//                       style: TextStyle(color: Colors.grey.shade600),
//                     ),
//                 ],
//               ),
//               trailing: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade100,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   'Expired',
//                   style: TextStyle(
//                     color: Colors.red.shade700,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: Column(
//         children: [
//           // Add a refresh button at the top
//           Container(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.refresh),
//                   onPressed: _isLoadingExpiredJobs ? null : fetchExpiredJobs,
//                   tooltip: 'Refresh',
//                 ),
//               ],
//             ),
//           ),
//           Expanded(child: buildExpiredJobsList()),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';

class ExpiredJobsContent extends StatefulWidget {
  const ExpiredJobsContent({Key? key}) : super(key: key);

  @override
  State<ExpiredJobsContent> createState() => _ExpiredJobsContentState();
}

class _ExpiredJobsContentState extends State<ExpiredJobsContent> {
  // Variables for expired jobs
  List<dynamic> _expiredJobsList = [];
  bool _isLoadingExpiredJobs = false;
  String? _errorMessage;
  String? _authToken;
  Map<int, bool> _jobRatingStatus = {}; // Track which jobs are already rated
  Map<int, bool> _isSubmittingRating = {}; // Track rating submission status

  @override
  void initState() {
    super.initState();
    loadTokenAndFetchExpiredJobs();
  }

  // Load authentication token from SharedPreferences
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('access_token');
    });
  }

  // Get authorization headers
  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
  }

  // Check if rating exists for a job
  Future<bool> checkRatingExists(int jobId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/ratings/?rater_type=business&ratee_type=user&job_post=$jobId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> ratings = json.decode(response.body);
        return ratings.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking rating: $e');
      return false;
    }
  }

  // Submit rating for a driver
  Future<bool> submitRating(int jobId, int driverId, int rating, String comment) async {
    try {
      setState(() {
        _isSubmittingRating[jobId] = true;
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ratings/'),
        headers: _getAuthHeaders(),
        body: json.encode({
          'job': jobId,
          'ratee': driverId,
          'rating': rating,
          'comment': comment,
          'rater_type': 'business',
          'ratee_type': 'user',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _jobRatingStatus[jobId] = true;
          _isSubmittingRating[jobId] = false;
        });
        return true;
      } else {
        setState(() {
          _isSubmittingRating[jobId] = false;
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _isSubmittingRating[jobId] = false;
      });
      print('Error submitting rating: $e');
      return false;
    }
  }

  // Show rating dialog
  void showRatingDialog(BuildContext context, dynamic job) {
    int selectedRating = 5;
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate Driver'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rate ${job['hired_driver']['username']}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          color: index < selectedRating ? Colors.amber : Colors.grey,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSubmittingRating[job['id']] == true
                      ? null
                      : () async {
                          final success = await submitRating(
                            job['id'],
                            job['hired_driver']['id'],
                            selectedRating,
                            commentController.text,
                          );
                          
                          Navigator.pop(context);
                          
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Rating submitted successfully')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to submit rating')),
                            );
                          }
                        },
                  child: _isSubmittingRating[job['id']] == true
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fetch expired/archived jobs
  Future<void> fetchExpiredJobs() async {
    setState(() {
      _isLoadingExpiredJobs = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/jobs/archived/'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> expiredJobs = json.decode(response.body);

        // Check rating status for jobs with hired drivers
        for (var job in expiredJobs) {
          if (job['hired_driver'] != null) {
            final hasRating = await checkRatingExists(job['id']);
            _jobRatingStatus[job['id']] = hasRating;
          }
        }

        setState(() {
          _expiredJobsList = expiredJobs;
          _isLoadingExpiredJobs = false;
        });
        print('Fetched ${expiredJobs.length} expired jobs');
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch expired jobs: ${response.statusCode}';
          _isLoadingExpiredJobs = false;
        });
        print('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching expired jobs: ${e.toString()}';
        _isLoadingExpiredJobs = false;
      });
      print('Exception: $e');
    }
  }

  // Load token and fetch expired jobs
  Future<void> loadTokenAndFetchExpiredJobs() async {
    try {
      await _loadToken();
      if (_authToken != null) {
        await fetchExpiredJobs();
      } else {
        setState(() {
          _errorMessage = 'No authentication token found. Please login again.';
          _isLoadingExpiredJobs = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoadingExpiredJobs = false;
      });
    }
  }

  // Widget to display expired jobs
  Widget buildExpiredJobsList() {
    if (_isLoadingExpiredJobs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadTokenAndFetchExpiredJobs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_expiredJobsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No expired jobs found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchExpiredJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _expiredJobsList.length,
        itemBuilder: (context, index) {
          final job = _expiredJobsList[index];
          final hasHiredDriver = job['hired_driver'] != null;
          final isAlreadyRated = _jobRatingStatus[job['id']] ?? false;
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Text(
                job['title'] ?? 'No Title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    job['description'] ?? 'No Description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${job['job_date'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    'Rate: £${job['hourly_rate'] ?? '0'}/hr',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (job['business_detail'] != null)
                    Text(
                      'Business: ${job['business_detail']['name'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  // Show hired driver info
                  if (hasHiredDriver) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Driver: ${job['hired_driver']['username'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  // Show rating button if driver was hired but not yet rated
                  if (hasHiredDriver && !isAlreadyRated) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => showRatingDialog(context, job),
                      icon: const Icon(Icons.star, size: 16),
                      label: const Text('Rate Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 32),
                      ),
                    ),
                  ],
                  // Show if already rated
                  if (hasHiredDriver && isAlreadyRated) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, 
                               size: 16, 
                               color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Driver Rated',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Show if no driver was hired
                  if (!hasHiredDriver) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No Driver Hired',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Expired',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Add a refresh button at the top
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoadingExpiredJobs ? null : fetchExpiredJobs,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          Expanded(child: buildExpiredJobsList()),
        ],
      ),
    );
  }
}