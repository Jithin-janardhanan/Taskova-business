// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:taskova_shopkeeper/Model/api_config.dart';
// import 'package:taskova_shopkeeper/view/Jobpost/job_manage.dart';
// import 'package:taskova_shopkeeper/view/Jobpost/subscription.dart';
// import 'package:taskova_shopkeeper/view/Jobpost/mypost.dart';

// class ScheduleJobPost extends StatefulWidget {
//   const ScheduleJobPost({super.key});

//   @override
//   _ScheduleJobPostState createState() => _ScheduleJobPostState();
// }

// class _ScheduleJobPostState extends State<ScheduleJobPost> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   bool _isLoadingBusinesses = true;
//   List<dynamic> _businesses = [];
//   int? _selectedBusinessId;
//   String? _authToken;
//   int? _shopkeeperId;

//   final _titleController = TextEditingController(text: 'Drivers Needed TODAY!');
//   final _descriptionController = TextEditingController();
//   final _hourlyRateController = TextEditingController(text: '15');
//   final _perDeliveryRateController = TextEditingController(text: '3');

//   DateTime _postDate = DateTime.now();
//   DateTime _startTime = DateTime(
//     DateTime.now().year,
//     DateTime.now().month,
//     DateTime.now().day,
//     9,
//     0,
//   );
//   DateTime _endTime = DateTime(
//     DateTime.now().year,
//     DateTime.now().month,
//     DateTime.now().day,
//     17,
//     0,
//   );

//   bool _showHourlyRate = true;
//   bool _showPerDeliveryRate = true;

//   final String _apiUrlBusinesses = ApiConfig.businesses;
//   final String _apiUrlJobPosts = ApiConfig.jobposts;

//   @override
//   void initState() {
//     super.initState();
//     _loadToken().then((_) {
//       _fetchBusinesses();
//       _fetchAndStoreShopkeeperId();
//     });
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _hourlyRateController.dispose();
//     _perDeliveryRateController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       setState(() {
//         _authToken = prefs.getString('access_token');
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load token: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Map<String, String> _getAuthHeaders() {
//     return {
//       'Authorization': 'Bearer $_authToken',
//       'Content-Type': 'application/json',
//     };
//   }

//   Future<void> _fetchBusinesses() async {
//     if (_authToken == null) {
//       if (mounted) {
//         setState(() {
//           _isLoadingBusinesses = false;
//         });
//       }
//       return;
//     }

//     try {
//       final response = await http.get(
//         Uri.parse(_apiUrlBusinesses),
//         headers: _getAuthHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (mounted) {
//           setState(() {
//             _businesses = data;
//             if (_businesses.isNotEmpty) {
//               _selectedBusinessId = _businesses[0]['id'];
//             }
//           });
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Failed to fetch businesses: ${response.statusCode}',
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching businesses: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingBusinesses = false;
//         });
//       }
//     }
//   }

//   Future<void> _selectTime(BuildContext context, bool isStartTime) async {
//     TimeOfDay initialTime =
//         isStartTime
//             ? TimeOfDay.fromDateTime(_startTime)
//             : TimeOfDay.fromDateTime(_endTime);

//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: initialTime,
//     );

//     if (picked != null && mounted) {
//       setState(() {
//         if (isStartTime) {
//           _startTime = DateTime(
//             _postDate.year,
//             _postDate.month,
//             _postDate.day,
//             picked.hour,
//             picked.minute,
//           );
//         } else {
//           _endTime = DateTime(
//             _postDate.year,
//             _postDate.month,
//             _postDate.day,
//             picked.hour,
//             picked.minute,
//           );
//         }
//       });
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _postDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 7)),
//     );

//     if (picked != null && mounted) {
//       setState(() {
//         _postDate = picked;
//         _startTime = DateTime(
//           picked.year,
//           picked.month,
//           picked.day,
//           _startTime.hour,
//           _startTime.minute,
//         );
//         _endTime = DateTime(
//           picked.year,
//           picked.month,
//           picked.day,
//           _endTime.hour,
//           _endTime.minute,
//         );
//       });
//     }
//   }

//   Future<void> _publishJobPosting() async {
//     if (!_formKey.currentState!.validate()) return;

//     // Validate time selection
//     if (_startTime.isAfter(_endTime)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Start time must be before end time')),
//       );
//       return;
//     }

//     final jobPostingData = {
//       "business": _selectedBusinessId,
//       "title": _titleController.text,
//       "description": _descriptionController.text,
//       "job_date": DateFormat('yyyy-MM-dd').format(_postDate),
//       "start_time": DateFormat('HH:mm:ss').format(_startTime),
//       "end_time": DateFormat('HH:mm:ss').format(_endTime),
//       "hourly_rate": _showHourlyRate ? _hourlyRateController.text : null,
//       "per_delivery_rate":
//           _showPerDeliveryRate ? _perDeliveryRateController.text : null,
//       "complimentary_benefits": [],
//       "is_active": true,
//     };

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse(_apiUrlJobPosts),
//         headers: _getAuthHeaders(),
//         body: json.encode(jobPostingData),
//       );

//       if (mounted) {
//         if (response.statusCode == 200 || response.statusCode == 201) {
//           // Use pushReplacement to prevent going back to this screen
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (context) => const JobManagementPage()),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Failed to post job: ${response.statusCode}'),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchAndStoreShopkeeperId() async {
//     if (_authToken == null) return;

//     try {
//       final url = Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/profile/');
//       final response = await http.get(url, headers: _getAuthHeaders());

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final profileId = data['personal_profile']?['id'];
//         if (mounted && profileId != null) {
//           setState(() {
//             _shopkeeperId = profileId;
//           });
//         }
//       }
//     } catch (e) {
//       // Handle error silently or log it
//       debugPrint('Error fetching shopkeeper profile: $e');
//     }
//   }

//   Future<int?> _fetchShopkeeperProfileId() async {
//     // Return stored ID if available
//     if (_shopkeeperId != null) {
//       return _shopkeeperId;
//     }

//     try {
//       final url = Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/profile/');
//       final response = await http.get(url, headers: _getAuthHeaders());

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final profileId = data['personal_profile']?['id'];

//         // Store the ID for future use
//         if (mounted && profileId != null) {
//           setState(() {
//             _shopkeeperId = profileId;
//           });
//         }

//         return profileId;
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Failed to load profile: ${response.statusCode}'),
//             ),
//           );
//         }
//         return null;
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading profile: ${e.toString()}')),
//         );
//       }
//       return null;
//     }
//   }

//   // Replace your existing _fetchSubscriptionStatus and _checkSubscriptionAndProceed methods with these updated versions

//   Future<Map<String, dynamic>?> _fetchSubscriptionStatus(
//     int shopkeeperId,
//   ) async {
//     try {
//       final url = Uri.parse(
//         '${ApiConfig.baseUrl}/api/subscriptions/current/?shopkeeper_id=$shopkeeperId',
//       );
//       final response = await http.get(url, headers: _getAuthHeaders());

//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Failed to fetch subscription status: ${response.statusCode}',
//               ),
//             ),
//           );
//         }
//         return null;
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error fetching subscription: ${e.toString()}'),
//           ),
//         );
//       }
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>?> _checkJobPostingLimits() async {
//     try {
//       final url = Uri.parse('${ApiConfig.baseUrl}/api/job-posts/create/');
//       final response = await http.get(url, headers: _getAuthHeaders());

//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Failed to check job posting limits: ${response.statusCode}',
//               ),
//             ),
//           );
//         }
//         return null;
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error checking job posting limits: ${e.toString()}'),
//           ),
//         );
//       }
//       return null;
//     }
//   }

//   Future<void> _checkSubscriptionAndProceed() async {
//     // First check the job creation API directly
//     final jobLimits = await _checkJobPostingLimits();
//     if (jobLimits == null) return;

//     final status = jobLimits['status'];
//     final message = jobLimits['message'];
//     final limitPlanType = jobLimits['plan_type'];
//     final maxScheduledJobs = jobLimits['max_scheduled_jobs'] ?? 0;
//     final scheduledJobsCount = jobLimits['scheduled_jobs_count'] ?? 0;

//     // Handle different plan types from job creation API
//     if (limitPlanType == 'TRIAL') {
//       // Trial users can post jobs directly - no message needed
//       await _publishJobPosting();
//       return;
//     }

//     if (limitPlanType == 'NONE') {
//       // User has no subscription - show popup
//       if (mounted) {
//         final shouldNavigate = await showDialog<bool>(
//           context: context,
//           barrierDismissible: false,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text('Subscription Required'),
//               content: Text(
//                 message ??
//                     'You currently have no active trial or subscription. Please subscribe to post jobs.',
//               ),
//               actions: [
//                 TextButton(
//                   child: const Text('Cancel'),
//                   onPressed: () {
//                     Navigator.of(context).pop(false);
//                   },
//                 ),
//                 ElevatedButton(
//                   child: const Text('OK'),
//                   onPressed: () {
//                     Navigator.of(context).pop(true);
//                   },
//                 ),
//               ],
//             );
//           },
//         );

//         if (shouldNavigate == true) {
//           final result = await Navigator.push<bool>(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const SubscriptionPlansPage(),
//             ),
//           );

//           if (result == true) {
//             await _checkSubscriptionAndProceed();
//           }
//         }
//       }
//       return;
//     }

//     if (limitPlanType == 'PREMIUM') {
//       // Premium users - check scheduling limits
//       if (scheduledJobsCount < maxScheduledJobs) {
//         await _publishJobPosting();
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'You have reached your scheduled jobs limit ($maxScheduledJobs). You currently have $scheduledJobsCount scheduled jobs.',
//               ),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//       return;
//     }

//     if (limitPlanType == 'BASIC') {
//       // Basic users need to upgrade
//       if (mounted) {
//         final shouldNavigate = await showDialog<bool>(
//           context: context,
//           barrierDismissible: false,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text('Premium Required'),
//               content: const Text(
//                 'Schedule job posting is only available for Premium subscribers. Please upgrade to Premium.',
//               ),
//               actions: [
//                 TextButton(
//                   child: const Text('Cancel'),
//                   onPressed: () {
//                     Navigator.of(context).pop(false);
//                   },
//                 ),
//                 ElevatedButton(
//                   child: const Text('OK'),
//                   onPressed: () {
//                     Navigator.of(context).pop(true);
//                   },
//                 ),
//               ],
//             );
//           },
//         );

//         if (shouldNavigate == true) {
//           final result = await Navigator.push<bool>(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const SubscriptionPlansPage(),
//             ),
//           );

//           if (result == true) {
//             await _checkSubscriptionAndProceed();
//           }
//         }
//       }
//       return;
//     }

//     // If we reach here, we need to check subscription status for other plan types
//     int? shopkeeperId = _shopkeeperId;
//     if (shopkeeperId == null) {
//       shopkeeperId = await _fetchShopkeeperProfileId();
//       if (shopkeeperId == null) return;
//     }

//     final subscription = await _fetchSubscriptionStatus(shopkeeperId);
//     if (subscription == null) return;

//     final planType = subscription['plan_type'];

//     switch (planType) {
//       case 'TRIAL':
//         // Trial users can post jobs
//         await _publishJobPosting();
//         break;

//       case 'PREMIUM':
//         // Check if premium user has reached scheduling limits
//         if (limitPlanType == 'PREMIUM' &&
//             scheduledJobsCount < maxScheduledJobs) {
//           await _publishJobPosting();
//         } else if (limitPlanType == 'PREMIUM' &&
//             scheduledJobsCount >= maxScheduledJobs) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   'You have reached your scheduled jobs limit ($maxScheduledJobs). You currently have $scheduledJobsCount scheduled jobs.',
//                 ),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         } else {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(message ?? 'Unable to verify scheduling limits.'),
//                 backgroundColor: Colors.orange,
//               ),
//             );
//           }
//         }
//         break;

//       case 'BASIC':
//       default:
//         // Basic users need to upgrade
//         if (mounted) {
//           final shouldNavigate = await showDialog<bool>(
//             context: context,
//             barrierDismissible: false,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text('Premium Required'),
//                 content: const Text(
//                   'Schedule job posting is only available for Premium subscribers. Please upgrade to Premium.',
//                 ),
//                 actions: [
//                   TextButton(
//                     child: const Text('Cancel'),
//                     onPressed: () {
//                       Navigator.of(context).pop(false);
//                     },
//                   ),
//                   ElevatedButton(
//                     child: const Text('OK'),
//                     onPressed: () {
//                       Navigator.of(context).pop(true);
//                     },
//                   ),
//                 ],
//               );
//             },
//           );

//           if (shouldNavigate == true) {
//             final result = await Navigator.push<bool>(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const SubscriptionPlansPage(),
//               ),
//             );

//             if (result == true) {
//               await _checkSubscriptionAndProceed();
//             }
//           }
//         }
//         break;
//     }
//   }

//   // Helper method to check specific features based on plan type
//   bool _hasFeatureAccess(Map<String, dynamic> subscription, String feature) {
//     final planType = subscription['plan_type'];
//     final isActive = subscription['is_active'] ?? false;

//     if (!isActive) return false;

//     // Define feature access based on plan type
//     switch (planType) {
//       case 'PREMIUM':
//         return true; // Premium has access to all features
//       case 'BASIC':
//         // Define basic plan limitations here
//         return ['basic_job_posting', 'basic_messaging'].contains(feature);
//       default:
//         // Trial users get limited access
//         return ['trial_job_posting'].contains(feature);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_authToken == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Create Job Post')),
//         body: const Center(child: Text('Please log in to create job postings')),
//       );
//     }

//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Create Job Post')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Create Job Post')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 if (_isLoadingBusinesses)
//                   const CircularProgressIndicator()
//                 else if (_businesses.isNotEmpty)
//                   DropdownButtonFormField<int>(
//                     decoration: const InputDecoration(labelText: 'Business'),
//                     value: _selectedBusinessId,
//                     items:
//                         _businesses.map((business) {
//                           return DropdownMenuItem<int>(
//                             value: business['id'],
//                             child: Text(business['name'] ?? 'Unknown Business'),
//                           );
//                         }).toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedBusinessId = value;
//                       });
//                     },
//                     validator:
//                         (value) =>
//                             value == null ? 'Please select a business' : null,
//                   )
//                 else
//                   const Text('No businesses available'),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _titleController,
//                   decoration: const InputDecoration(labelText: 'Job Title'),
//                   validator:
//                       (value) =>
//                           value == null || value.isEmpty
//                               ? 'Please enter a job title'
//                               : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _descriptionController,
//                   decoration: const InputDecoration(labelText: 'Description'),
//                   maxLines: 3,
//                   validator:
//                       (value) =>
//                           value == null || value.isEmpty
//                               ? 'Please enter a description'
//                               : null,
//                 ),
//                 const SizedBox(height: 16),
//                 Card(
//                   child: ListTile(
//                     title: Text(
//                       'Date: ${DateFormat('MMM d, yyyy').format(_postDate)}',
//                     ),
//                     trailing: const Icon(Icons.calendar_today),
//                     onTap: () => _selectDate(context),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Card(
//                         child: ListTile(
//                           title: Text(
//                             'Start: ${DateFormat('h:mm a').format(_startTime)}',
//                           ),
//                           trailing: const Icon(Icons.access_time),
//                           onTap: () => _selectTime(context, true),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Card(
//                         child: ListTile(
//                           title: Text(
//                             'End: ${DateFormat('h:mm a').format(_endTime)}',
//                           ),
//                           trailing: const Icon(Icons.access_time),
//                           onTap: () => _selectTime(context, false),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 if (_showHourlyRate)
//                   TextFormField(
//                     controller: _hourlyRateController,
//                     decoration: const InputDecoration(
//                       labelText: 'Hourly Rate (£)',
//                     ),
//                     keyboardType: TextInputType.number,
//                     validator: (value) {
//                       if (_showHourlyRate && (value == null || value.isEmpty)) {
//                         return 'Please enter hourly rate';
//                       }
//                       if (value != null && value.isNotEmpty) {
//                         final rate = double.tryParse(value);
//                         if (rate == null || rate <= 0) {
//                           return 'Please enter a valid rate';
//                         }
//                       }
//                       return null;
//                     },
//                   ),
//                 const SizedBox(height: 16),
//                 if (_showPerDeliveryRate)
//                   TextFormField(
//                     controller: _perDeliveryRateController,
//                     decoration: const InputDecoration(
//                       labelText: 'Per Delivery Rate (£)',
//                     ),
//                     keyboardType: TextInputType.number,
//                     validator: (value) {
//                       if (_showPerDeliveryRate &&
//                           (value == null || value.isEmpty)) {
//                         return 'Please enter per delivery rate';
//                       }
//                       if (value != null && value.isNotEmpty) {
//                         final rate = double.tryParse(value);
//                         if (rate == null || rate <= 0) {
//                           return 'Please enter a valid rate';
//                         }
//                       }
//                       return null;
//                     },
//                   ),
//                 const SizedBox(height: 32),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _checkSubscriptionAndProceed,
//                     child:
//                         _isLoading
//                             ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             )
//                             : const Text('PUBLISH JOB'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/view/Jobpost/job_manage.dart';
import 'package:taskova_shopkeeper/view/Jobpost/subscription.dart';
import 'package:taskova_shopkeeper/view/Jobpost/mypost.dart';

class ScheduleJobPost extends StatefulWidget {
  const ScheduleJobPost({super.key});

  @override
  _ScheduleJobPostState createState() => _ScheduleJobPostState();
}

class _ScheduleJobPostState extends State<ScheduleJobPost> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingBusinesses = true;
  List<dynamic> _businesses = [];
  int? _selectedBusinessId;
  String? _authToken;
  int? _shopkeeperId;

  final _titleController = TextEditingController(text: 'Drivers Needed TODAY!');
  final _hourlyRateController = TextEditingController(text: '15');
  final _perDeliveryRateController = TextEditingController(text: '3');

  DateTime? _postDate; // Changed to nullable
  DateTime? _startTime; // Changed to nullable
  DateTime? _endTime; // Changed to nullable

  String? _selectedDescription; // Changed to dropdown selection
  bool _showHourlyRate = true;
  bool _showPerDeliveryRate = true;

  final String _apiUrlBusinesses = ApiConfig.businesses;
  final String _apiUrlJobPosts = ApiConfig.jobposts;

  // Predefined description options
  final List<Map<String, String>> _descriptionOptions = [
    {
      'title': 'General Delivery Driver',
      'description': 'Responsible for timely delivery of goods to customers, maintaining vehicle condition, and ensuring accurate order fulfillment.'
    },
    {
      'title': 'Package Delivery Specialist',
      'description': 'Handle package pickups and deliveries across designated routes, ensuring prompt and safe transport of items.'
    },
    {
      'title': 'Food Delivery Driver',
      'description': 'Deliver food orders to customers efficiently, maintaining food quality and providing excellent customer service.'
    },
    {
      'title': 'Freight Transport Driver',
      'description': 'Transport large shipments between locations, ensuring secure handling and adherence to delivery schedules.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadToken().then((_) {
      _fetchBusinesses();
      _fetchAndStoreShopkeeperId();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hourlyRateController.dispose();
    _perDeliveryRateController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _authToken = prefs.getString('access_token');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load token: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _fetchBusinesses() async {
    if (_authToken == null) {
      if (mounted) {
        setState(() {
          _isLoadingBusinesses = false;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(_apiUrlBusinesses),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _businesses = data;
            if (_businesses.isNotEmpty) {
              _selectedBusinessId = _businesses[0]['id'];
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to fetch businesses: ${response.statusCode}'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching businesses: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBusinesses = false;
        });
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[800]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.blue[800]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final now = DateTime.now();
      final selectedDate = _postDate ?? now;
      
      setState(() {
        if (isStartTime) {
          _startTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            picked.hour,
            picked.minute,
          );
        } else {
          _endTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[800]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.blue[800]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _postDate = picked;
        // Reset times when date changes
        if (_startTime != null) {
          _startTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _startTime!.hour,
            _startTime!.minute,
          );
        }
        if (_endTime != null) {
          _endTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _endTime!.hour,
            _endTime!.minute,
          );
        }
      });
    }
  }

  Future<void> _publishJobPosting() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    // Additional validation for required fields
    if (_postDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a date'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select start time'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    if (_endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select end time'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    if (_selectedDescription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a job description'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    // Validate time selection
    if (_startTime!.isAfter(_endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Start time must be before end time'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    final jobPostingData = {
      "business": _selectedBusinessId,
      "title": _titleController.text,
      "description": _selectedDescription,
      "job_date": DateFormat('yyyy-MM-dd').format(_postDate!),
      "start_time": DateFormat('HH:mm:ss').format(_startTime!),
      "end_time": DateFormat('HH:mm:ss').format(_endTime!),
      "hourly_rate": _showHourlyRate ? _hourlyRateController.text : null,
      "per_delivery_rate": _showPerDeliveryRate ? _perDeliveryRateController.text : null,
      "complimentary_benefits": [],
      "is_active": true,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrlJobPosts),
        headers: _getAuthHeaders(),
        body: json.encode(jobPostingData),
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const JobManagementPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to post job: ${response.statusCode}'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndStoreShopkeeperId() async {
    if (_authToken == null) return;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/profile/');
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profileId = data['personal_profile']?['id'];
        if (mounted && profileId != null) {
          setState(() {
            _shopkeeperId = profileId;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching shopkeeper profile: $e');
    }
  }

  Future<int?> _fetchShopkeeperProfileId() async {
    if (_shopkeeperId != null) {
      return _shopkeeperId;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/profile/');
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profileId = data['personal_profile']?['id'];

        if (mounted && profileId != null) {
          setState(() {
            _shopkeeperId = profileId;
          });
        }

        return profileId;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: ${response.statusCode}'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchSubscriptionStatus(int shopkeeperId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/current/?shopkeeper_id=$shopkeeperId');
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to fetch subscription status: ${response.statusCode}'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching subscription: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _checkJobPostingLimits() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/job-posts/create/');
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to check job posting limits: ${response.statusCode}'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking job posting limits: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      return null;
    }
  }

  Future<void> _checkSubscriptionAndProceed() async {
    final jobLimits = await _checkJobPostingLimits();
    if (jobLimits == null) return;

    final status = jobLimits['status'];
    final message = jobLimits['message'];
    final limitPlanType = jobLimits['plan_type'];
    final maxScheduledJobs = jobLimits['max_scheduled_jobs'] ?? 0;
    final scheduledJobsCount = jobLimits['scheduled_jobs_count'] ?? 0;

    if (limitPlanType == 'TRIAL') {
      await _publishJobPosting();
      return;
    }

    if (limitPlanType == 'NONE') {
      if (mounted) {
        final shouldNavigate = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                'Subscription Required',
                style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
              ),
              content: Text(
                message ?? 'You currently have no active trial or subscription. Please subscribe to post jobs.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );

        if (shouldNavigate == true) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionPlansPage()),
          );

          if (result == true) {
            await _checkSubscriptionAndProceed();
          }
        }
      }
      return;
    }

    if (limitPlanType == 'PREMIUM') {
      if (scheduledJobsCount < maxScheduledJobs) {
        await _publishJobPosting();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have reached your scheduled jobs limit ($maxScheduledJobs). You currently have $scheduledJobsCount scheduled jobs.',
              ),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
      return;
    }

    if (limitPlanType == 'BASIC') {
      if (mounted) {
        final shouldNavigate = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                'Premium Required',
                style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Schedule job posting is only available for Premium subscribers. Please upgrade to Premium.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );

        if (shouldNavigate == true) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionPlansPage()),
          );

          if (result == true) {
            await _checkSubscriptionAndProceed();
          }
        }
      }
      return;
    }

    // Handle other subscription checks...
    int? shopkeeperId = _shopkeeperId;
    if (shopkeeperId == null) {
      shopkeeperId = await _fetchShopkeeperProfileId();
      if (shopkeeperId == null) return;
    }

    final subscription = await _fetchSubscriptionStatus(shopkeeperId);
    if (subscription == null) return;

    final planType = subscription['plan_type'];

    switch (planType) {
      case 'TRIAL':
        await _publishJobPosting();
        break;
      case 'PREMIUM':
        if (limitPlanType == 'PREMIUM' && scheduledJobsCount < maxScheduledJobs) {
          await _publishJobPosting();
        } else if (limitPlanType == 'PREMIUM' && scheduledJobsCount >= maxScheduledJobs) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You have reached your scheduled jobs limit ($maxScheduledJobs). You currently have $scheduledJobsCount scheduled jobs.',
                ),
                backgroundColor: Colors.red[700],
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message ?? 'Unable to verify scheduling limits.'),
                backgroundColor: Colors.orange[700],
              ),
            );
          }
        }
        break;
      case 'BASIC':
      default:
        if (mounted) {
          final shouldNavigate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  'Premium Required',
                  style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'Schedule job posting is only available for Premium subscribers. Please upgrade to Premium.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          );

          if (shouldNavigate == true) {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (context) => const SubscriptionPlansPage()),
            );

            if (result == true) {
              await _checkSubscriptionAndProceed();
            }
          }
        }
        break;
    }
  }

  bool _hasFeatureAccess(Map<String, dynamic> subscription, String feature) {
    final planType = subscription['plan_type'];
    final isActive = subscription['is_active'] ?? false;

    if (!isActive) return false;

    switch (planType) {
      case 'PREMIUM':
        return true;
      case 'BASIC':
        return ['basic_job_posting', 'basic_messaging'].contains(feature);
      default:
        return ['trial_job_posting'].contains(feature);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authToken == null) {
      return Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          title: const Text('Create Job Post'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Please log in to create job postings',
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          title: const Text('Create Job Post'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Create Job Post'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Business Selection Card
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoadingBusinesses
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
                            ),
                          )
                        : _businesses.isNotEmpty
                            ? DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Business *',
                                  labelStyle: TextStyle(color: Colors.blue[800]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.blue[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                                  ),
                                ),
                                value: _selectedBusinessId,
                                items: _businesses.map((business) {
                                  return DropdownMenuItem<int>(
                                    value: business['id'],
                                    child: Text(
                                      business['name'] ?? 'Unknown Business',
                                      style: TextStyle(color: Colors.blue[800]),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBusinessId = value;
                                  });
                                },
                                validator: (value) => value == null ? 'Please select a business' : null,
                              )
                            : Text(
                                'No businesses available',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                  ),
                ),

                // Job Title Card
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Job Title *',
                        labelStyle: TextStyle(color: Colors.blue[800]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a job title' : null,
                    ),
                  ),
                ),

                // Job Description Card
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Job Description *',
                        labelStyle: TextStyle(color: Colors.blue[800]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                        ),
                      ),
                      value: _selectedDescription,
                      items: _descriptionOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option['description'],
                          child: Text(
                            option['title']!,
                            style: TextStyle(color: Colors.blue[800]),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDescription = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a job description' : null,
                    ),
                  ),
                ),

                // Date Selection Card
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _postDate == null ? Colors.red[300]! : Colors.blue[300]!,
                            width: _postDate == null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _postDate == null
                                  ? 'Select Date *'
                                  : 'Date: ${DateFormat('MMM d, yyyy').format(_postDate!)}',
                              style: TextStyle(
                                color: _postDate == null ? Colors.red[700] : Colors.blue[800],
                                fontSize: 16,
                                fontWeight: _postDate == null ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: _postDate == null ? Colors.red[600] : Colors.blue[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Time Selection Card
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _startTime == null ? Colors.red[300]! : Colors.blue[300]!,
                                  width: _startTime == null ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _startTime == null
                                        ? 'Start Time *'
                                        : 'Start: ${DateFormat('h:mm a').format(_startTime!)}',
                                    style: TextStyle(
                                      color: _startTime == null ? Colors.red[700] : Colors.blue[800],
                                      fontSize: 14,
                                      fontWeight: _startTime == null ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: _startTime == null ? Colors.red[600] : Colors.blue[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _endTime == null ? Colors.red[300]! : Colors.blue[300]!,
                                  width: _endTime == null ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _endTime == null
                                        ? 'End Time *'
                                        : 'End: ${DateFormat('h:mm a').format(_endTime!)}',
                                    style: TextStyle(
                                      color: _endTime == null ? Colors.red[700] : Colors.blue[800],
                                      fontSize: 14,
                                      fontWeight: _endTime == null ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: _endTime == null ? Colors.red[600] : Colors.blue[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Rates Card
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_showHourlyRate)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: _hourlyRateController,
                              decoration: InputDecoration(
                                labelText: 'Hourly Rate (£) *',
                                labelStyle: TextStyle(color: Colors.blue[800]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                                ),
                                prefixIcon: Icon(Icons.attach_money, color: Colors.blue[600]),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_showHourlyRate && (value == null || value.isEmpty)) {
                                  return 'Please enter hourly rate';
                                }
                                if (value != null && value.isNotEmpty) {
                                  final rate = double.tryParse(value);
                                  if (rate == null || rate <= 0) {
                                    return 'Please enter a valid rate';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        if (_showPerDeliveryRate)
                          TextFormField(
                            controller: _perDeliveryRateController,
                            decoration: InputDecoration(
                              labelText: 'Per Delivery Rate (£) *',
                              labelStyle: TextStyle(color: Colors.blue[800]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                              ),
                              prefixIcon: Icon(Icons.local_shipping, color: Colors.blue[600]),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_showPerDeliveryRate && (value == null || value.isEmpty)) {
                                return 'Please enter per delivery rate';
                              }
                              if (value != null && value.isNotEmpty) {
                                final rate = double.tryParse(value);
                                if (rate == null || rate <= 0) {
                                  return 'Please enter a valid rate';
                                }
                              }
                              return null;
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // Publish Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[900]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkSubscriptionAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'PUBLISH JOB',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
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
}