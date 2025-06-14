// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_shopkeeper/Model/api_config.dart';

// // You'll need to import your ApiConfig
// // import 'your_api_config.dart';

// class ExpiredJobsPage extends StatefulWidget {
//   const ExpiredJobsPage({Key? key}) : super(key: key);

//   @override
//   State<ExpiredJobsPage> createState() => _ExpiredJobsPageState();
// }

// class _ExpiredJobsPageState extends State<ExpiredJobsPage> {
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
//       appBar: AppBar(
//         title: const Text('Expired Jobs'),
//         backgroundColor: const Color.fromARGB(255, 30, 38, 185),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _isLoadingExpiredJobs ? null : fetchExpiredJobs,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: buildExpiredJobsList(),
//     );
//   }
// }
// Add this class to your existing expired_jobs_page.dart file

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

  @override
  void initState() {
    super.initState();
    loadTokenAndFetchExpiredJobs();
  }

  // Load authentication token from SharedPreferences
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString(
        'access_token',
      ); // Or whatever your actual key is
    });
  }

  // Get authorization headers
  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
  }

  // Fetch expired/archived jobs
  Future<void> fetchExpiredJobs() async {
    setState(() {
      _isLoadingExpiredJobs = true;
      _errorMessage = null;
    });

    try {
      // Replace with your actual API endpoint
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/jobs/archived/',
        ), // Adjust baseUrl as needed
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> expiredJobs = json.decode(response.body);

        setState(() {
          _expiredJobsList = expiredJobs;
          _isLoadingExpiredJobs = false;
        });
        print('Fetched ${expiredJobs.length} expired jobs');
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch expired jobs: ${response.statusCode}';
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