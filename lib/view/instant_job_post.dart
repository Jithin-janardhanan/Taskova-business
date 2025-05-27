// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_shopkeeper/Model/api_config.dart';
// import 'package:taskova_shopkeeper/view/mypost.dart';

// class InstatJobPost extends StatefulWidget {
//   const InstatJobPost({super.key});

//   @override
//   _InstatJobPostState createState() => _InstatJobPostState();
// }

// class _InstatJobPostState extends State<InstatJobPost> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   bool _isLoadingBusinesses = true;
//   List<dynamic> _businesses = [];
//   int? _selectedBusinessId;
//   String? _authToken;

//   // Form controllers
//   final _titleController = TextEditingController(text: 'Drivers Needed TODAY!');
//   final _descriptionController = TextEditingController(text: '');
//   final _hourlyRateController = TextEditingController(text: '15');
//   final _perDeliveryRateController = TextEditingController(text: '3');

//   // Form values - Using today's date
//   final DateTime _postDate = DateTime.now();
//   late DateTime _startTime;
//   late DateTime _endTime;
//   bool _showHourlyRate = true;
//   bool _showPerDeliveryRate = true;
//   final List<String> _complimentaryOptions = [
//     'Meal during shift',
//     'Free drinks',
//     'Fuel allowance',
//   ];
//   final List<bool> _selectedComplimentary = [true, false, false];
//   String _newComplimentary = '';

//   // API endpoints
//   final String _apiUrlBusinesses = (ApiConfig.businesses);
//   final String _apiUrlJobPosts = (ApiConfig.jobposts);

//   @override
//   void initState() {
//     super.initState();
//     // Initialize start and end time with today's date and default hours
//     _startTime = DateTime(_postDate.year, _postDate.month, _postDate.day, 9, 0);
//     _endTime = DateTime(_postDate.year, _postDate.month, _postDate.day, 17, 0);
//     _loadToken().then((_) => _fetchBusinesses());
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _hourlyRateController.dispose();
//     _perDeliveryRateController.dispose();
//     super.dispose();
//   }

//   // Load authentication token
//   Future<void> _loadToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       setState(() {
//         _authToken = prefs.getString('access_token');
//       });

//       if (_authToken == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Not logged in. Please login first.')),
//         );
//         // Navigate back or to login page if needed
//         // Navigator.of(context).pushReplacementNamed('/login');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to load authentication data: ${e.toString()}'),
//         ),
//       );
//     }
//   }

//   // Create authorization header with token
//   Map<String, String> _getAuthHeaders() {
//     return {
//       'Authorization': 'Bearer $_authToken',
//       'Content-Type': 'application/json',
//     };
//   }

//   // Fetch businesses from API
//   Future<void> _fetchBusinesses() async {
//     if (_authToken == null) {
//       setState(() {
//         _isLoadingBusinesses = false;
//       });
//       return;
//     }

//     setState(() {
//       _isLoadingBusinesses = true;
//     });

//     try {
//       final headers = _getAuthHeaders();

//       final response = await http.get(
//         Uri.parse(_apiUrlBusinesses),
//         headers: headers,
//       );

//       setState(() {
//         _isLoadingBusinesses = false;
//       });

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         // Save businesses data to shared preferences
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('businesses_data', response.body);

//         setState(() {
//           _businesses = data;
//           // Select the first business by default if available
//           if (_businesses.isNotEmpty) {
//             _selectedBusinessId = _businesses[0]['id'];
//           }
//         });
//       } else if (response.statusCode == 401) {
//         // Token might be expired - handle authentication error
//         _handleAuthError();
//       } else {
//         // Try to load from cached data if API call fails
//         final prefs = await SharedPreferences.getInstance();
//         final cachedData = prefs.getString('businesses_data');
//         if (cachedData != null) {
//           setState(() {
//             _businesses = json.decode(cachedData);
//             if (_businesses.isNotEmpty) {
//               _selectedBusinessId = _businesses[0]['id'];
//             }
//           });
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Failed to load businesses: ${response.reasonPhrase}',
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoadingBusinesses = false;
//       });

//       // Try to load from cached data if error occurs
//       final prefs = await SharedPreferences.getInstance();
//       final cachedData = prefs.getString('businesses_data');
//       if (cachedData != null) {
//         setState(() {
//           _businesses = json.decode(cachedData);
//           if (_businesses.isNotEmpty) {
//             _selectedBusinessId = _businesses[0]['id'];
//           }
//         });
//       }

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Network error: ${e.toString()}')));
//     }
//   }

//   // Handle authentication errors
//   void _handleAuthError() async {
//     // Clear auth token
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('auth_token');

//     setState(() {
//       _authToken = null;
//     });

//     // Show message to user
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Your session has expired. Please log in again.'),
//         duration: Duration(seconds: 5),
//       ),
//     );

//     // Navigate to login page
//     // Navigator.of(context).pushReplacementNamed('/login');
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

//     if (picked != null) {
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

//   void _addComplimentaryOption() {
//     if (_newComplimentary.isNotEmpty) {
//       setState(() {
//         _complimentaryOptions.add(_newComplimentary);
//         _selectedComplimentary.add(true);
//         _newComplimentary = '';
//       });
//     }
//   }

//   // Validate time range
//   bool _validateTimeRange() {
//     return _startTime.isBefore(_endTime);
//   }

//   // Validate rates
//   bool _validateRates() {
//     if (_showHourlyRate) {
//       double? hourlyRate = double.tryParse(_hourlyRateController.text);
//       if (hourlyRate == null || hourlyRate <= 0) return false;
//     }

//     if (_showPerDeliveryRate) {
//       double? perDeliveryRate = double.tryParse(
//         _perDeliveryRateController.text,
//       );
//       if (perDeliveryRate == null || perDeliveryRate <= 0) return false;
//     }

//     return true;
//   }

//   Future<void> _publishJobPosting() async {
//     if (_authToken == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('You need to be logged in to post jobs')),
//       );
//       return;
//     }

//     if (_selectedBusinessId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a business first')),
//       );
//       return;
//     }

//     if (!_formKey.currentState!.validate()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please correct the errors in the form')),
//       );
//       return;
//     }

//     // Additional validation for time range
//     if (!_validateTimeRange()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('End time must be after start time')),
//       );
//       return;
//     }

//     // Additional validation for rates
//     if (!_validateRates()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Rates must be valid positive numbers')),
//       );
//       return;
//     }

//     // At least one selected benefit
//     final selectedBenefits =
//         List.generate(
//           _selectedComplimentary.length,
//           (index) =>
//               _selectedComplimentary[index]
//                   ? _complimentaryOptions[index]
//                   : null,
//         ).where((item) => item != null).toList();

//     // Create job posting data
//     final Map<String, dynamic> jobPostingData = {
//       "business": _selectedBusinessId,
//       "title": _titleController.text,
//       "description": _descriptionController.text,
//       "post_date": DateFormat('yyyy-MM-dd').format(_postDate),
//       "start_time": DateFormat('HH:mm:ss').format(_startTime),
//       "end_time": DateFormat('HH:mm:ss').format(_endTime),
//       "hourly_rate": _showHourlyRate ? _hourlyRateController.text : null,
//       "per_delivery_rate":
//           _showPerDeliveryRate ? _perDeliveryRateController.text : null,
//       "complimentary_benefits": selectedBenefits,
//       "created_at": DateTime.now().toUtc().toIso8601String(),
//       "updated_at": DateTime.now().toUtc().toIso8601String(),
//       "is_active": true,
//     };

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final headers = _getAuthHeaders();

//       // API call
//       final response = await http.post(
//         Uri.parse(_apiUrlJobPosts),
//         headers: headers,
//         body: json.encode(jobPostingData),
//       );

//       setState(() {
//         _isLoading = false;
//       });

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // Success
//         final responseData = json.decode(response.body);
//         _showSuccessDialog(responseData);
//       } else if (response.statusCode == 401) {
//         // Handle authentication error
//         _handleAuthError();
//       } else {
//         // Error handling
//         final errorData = json.decode(response.body);
//         _showErrorDialog(errorData.toString());
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       _showErrorDialog('Network error: ${e.toString()}');
//     }
//   }

//   void _showSuccessDialog(dynamic responseData) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Job Posted Successfully!'),
//           content: Text(
//             'Your driver job posting has been published. The job shift is scheduled for ${DateFormat('MMMM d, yyyy').format(_postDate)} from ${DateFormat('h:mm a').format(_startTime)} to ${DateFormat('h:mm a').format(_endTime)}.',
//           ),
//           actions: [
//            TextButton(
//   onPressed: () {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (context) => MyJobpost()),
//     );
//   },
//   child: const Text('OK'),
// ),
//           ],
//         );
//       },
//     );
//   }

//   void _showErrorDialog(String errorMessage) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Error'),
//           content: Text('Failed to post job: $errorMessage'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Create Driver Job Posting')),
//       body:
//           _authToken == null
//               ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       'Please log in to create job postings',
//                       style: TextStyle(fontSize: 18),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         // Navigate to login page
//                         // Navigator.of(context).pushReplacementNamed('/login');
//                       },
//                       child: const Text('Go to Login'),
//                     ),
//                   ],
//                 ),
//               )
//               : _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Business selection card
//                       Card(
//                         elevation: 4,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Select Business',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               _isLoadingBusinesses
//                                   ? const Center(
//                                     child: CircularProgressIndicator(),
//                                   )
//                                   : _businesses.isEmpty
//                                   ? const Text('No businesses found')
//                                   : DropdownButtonFormField<int>(
//                                     decoration: const InputDecoration(
//                                       labelText: 'Business',
//                                       border: OutlineInputBorder(),
//                                       filled: true,
//                                     ),
//                                     value: _selectedBusinessId,
//                                     items:
//                                         _businesses.map((business) {
//                                           return DropdownMenuItem<int>(
//                                             value: business['id'],
//                                             child: Text(business['name']),
//                                           );
//                                         }).toList(),
//                                     onChanged: (value) {
//                                       setState(() {
//                                         _selectedBusinessId = value;
//                                       });
//                                     },
//                                     validator: (value) {
//                                       if (value == null) {
//                                         return 'Please select a business';
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // Job Posting Details card
//                       Card(
//                         elevation: 4,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Job Posting Details',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               TextFormField(
//                                 controller: _titleController,
//                                 decoration: const InputDecoration(
//                                   labelText: 'Job Title',
//                                   border: OutlineInputBorder(),
//                                   filled: true,
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter a job title';
//                                   }
//                                   if (value.length < 5) {
//                                     return 'Title must be at least 5 characters';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                               const SizedBox(height: 16),
//                               TextFormField(
//                                 controller: _descriptionController,
//                                 decoration: const InputDecoration(
//                                   labelText: 'Job Description',
//                                   border: OutlineInputBorder(),
//                                   filled: true,
//                                 ),
//                                 maxLines: 5,
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter a job description';
//                                   }

//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // Schedule Settings card
//                       Card(
//                         elevation: 4,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Schedule Settings',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               ListTile(
//                                 title: const Text('Job Date'),
//                                 subtitle: Text(
//                                   DateFormat('MMMM d, yyyy').format(_postDate),
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 trailing: const Icon(Icons.calendar_today),
//                               ),
//                               const Divider(),
//                               ListTile(
//                                 title: const Text('Start Time'),
//                                 subtitle: Text(
//                                   DateFormat('h:mm a').format(_startTime),
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 trailing: const Icon(Icons.access_time),
//                                 onTap: () => _selectTime(context, true),
//                               ),
//                               const Divider(),
//                               ListTile(
//                                 title: const Text('End Time'),
//                                 subtitle: Text(
//                                   DateFormat('h:mm a').format(_endTime),
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 trailing: const Icon(Icons.access_time),
//                                 onTap: () => _selectTime(context, false),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // Payment Information card
//                       Card(
//                         elevation: 4,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Payment Information',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               CheckboxListTile(
//                                 title: const Text('Include Hourly Rate'),
//                                 value: _showHourlyRate,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _showHourlyRate = value ?? true;
//                                   });
//                                 },
//                               ),
//                               if (_showHourlyRate)
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 8,
//                                   ),
//                                   child: TextFormField(
//                                     controller: _hourlyRateController,
//                                     decoration: const InputDecoration(
//                                       labelText: 'Hourly Rate (£)',
//                                       border: OutlineInputBorder(),
//                                       filled: true,
//                                       prefixIcon: Icon(Icons.attach_money),
//                                     ),
//                                     keyboardType: TextInputType.number,
//                                     validator: (value) {
//                                       if (_showHourlyRate &&
//                                           (value == null || value.isEmpty)) {
//                                         return 'Please enter an hourly rate';
//                                       }
//                                       if (_showHourlyRate) {
//                                         double? rate = double.tryParse(value!);
//                                         if (rate == null) {
//                                           return 'Please enter a valid number';
//                                         }
//                                         if (rate <= 0) {
//                                           return 'Rate must be greater than zero';
//                                         }
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                                 ),
//                               const Divider(),
//                               CheckboxListTile(
//                                 title: const Text('Include Per Delivery Rate'),
//                                 value: _showPerDeliveryRate,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _showPerDeliveryRate = value ?? true;
//                                   });
//                                 },
//                               ),
//                               if (_showPerDeliveryRate)
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 8,
//                                   ),
//                                   child: TextFormField(
//                                     controller: _perDeliveryRateController,
//                                     decoration: const InputDecoration(
//                                       labelText: 'Per Delivery Rate (£)',
//                                       border: OutlineInputBorder(),
//                                       filled: true,
//                                       prefixIcon: Icon(Icons.local_shipping),
//                                     ),
//                                     keyboardType: TextInputType.number,
//                                     validator: (value) {
//                                       if (_showPerDeliveryRate &&
//                                           (value == null || value.isEmpty)) {
//                                         return 'Please enter a per delivery rate';
//                                       }
//                                       if (_showPerDeliveryRate) {
//                                         double? rate = double.tryParse(value!);
//                                         if (rate == null) {
//                                           return 'Please enter a valid number';
//                                         }
//                                         if (rate <= 0) {
//                                           return 'Rate must be greater than zero';
//                                         }
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // Complimentary Benefits card
//                       Card(
//                         elevation: 4,
//                         margin: const EdgeInsets.only(bottom: 20),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Complimentary Benefits',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               ...List.generate(
//                                 _complimentaryOptions.length,
//                                 (index) => CheckboxListTile(
//                                   title: Text(_complimentaryOptions[index]),
//                                   value: _selectedComplimentary[index],
//                                   onChanged: (value) {
//                                     setState(() {
//                                       _selectedComplimentary[index] =
//                                           value ?? false;
//                                     });
//                                   },
//                                 ),
//                               ),
//                               const Divider(),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: TextFormField(
//                                       decoration: const InputDecoration(
//                                         labelText: 'Add New Benefit',
//                                         border: OutlineInputBorder(),
//                                         filled: true,
//                                       ),
//                                       onChanged: (value) {
//                                         setState(() {
//                                           _newComplimentary = value;
//                                         });
//                                       },
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   IconButton(
//                                     icon: const Icon(Icons.add_circle),
//                                     color: Theme.of(context).primaryColor,
//                                     iconSize: 36,
//                                     onPressed: _addComplimentaryOption,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 20),
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton(
//                           onPressed: _publishJobPosting,
//                           style: ElevatedButton.styleFrom(
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: const Text(
//                             'PUBLISH JOB POSTING',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 40),
//                     ],
//                   ),
//                 ),
//               ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:taskova_shopkeeper/Model/api_config.dart';

class InstatJobPost extends StatefulWidget {
  const InstatJobPost({Key? key}) : super(key: key);

  @override
  _InstatJobPostState createState() => _InstatJobPostState();
}

class _InstatJobPostState extends State<InstatJobPost> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingBusinesses = true;
  List<dynamic> _businesses = [];
  int? _selectedBusinessId;
  String? _authToken;

  // Form controllers
  final _titleController = TextEditingController(text: 'Drivers Needed TODAY!');
  final _hourlyRateController = TextEditingController(text: '15');
  final _perDeliveryRateController = TextEditingController(text: '3');
  final _newComplimentaryController = TextEditingController();

  // Form values - Using today's date
  final DateTime _postDate = DateTime.now();
  late DateTime _startTime;
  late DateTime _endTime;
  bool _showHourlyRate = true;
  bool _showPerDeliveryRate = true;

  List<String> _complimentaryOptions = [
    'Meal during shift',
    'Free drinks',
    'Fuel allowance',
  ];
  List<bool> _selectedComplimentary = [true, false, false];
  String _newComplimentary = '';

  // Common job descriptions
  final List<Map<String, String>> _jobDescriptions = [
    {
      'title': 'Delivery Driver',
      'description':
          'Responsible for timely delivery of goods to customers, maintaining vehicle condition, and ensuring accurate order fulfillment.',
    },
    {
      'title': 'Courier Service',
      'description':
          'Handle package pickups and deliveries across designated routes, ensuring prompt and safe transport of items.',
    },
    {
      'title': 'Food Delivery',
      'description':
          'Deliver food orders to customers efficiently, maintaining food quality and providing excellent customer service.',
    },
    {
      'title': 'Freight Driver',
      'description':
          'Transport large shipments between locations, ensuring secure handling and adherence to delivery schedules.',
    },
  ];
  String? _selectedDescription;

  // API endpoints
  final String _apiUrlBusinesses = (ApiConfig.businesses);
  final String _apiUrlJobPosts = (ApiConfig.jobposts);

  //   @override
  void initState() {
    super.initState();
    // Initialize start and end time with today's date and default hours
    _startTime = DateTime(_postDate.year, _postDate.month, _postDate.day, 9, 0);
    _endTime = DateTime(_postDate.year, _postDate.month, _postDate.day, 17, 0);
    _loadToken().then((_) => _fetchBusinesses());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hourlyRateController.dispose();
    _perDeliveryRateController.dispose();
    _newComplimentaryController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _authToken = prefs.getString('access_token');
      });

      if (_authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in. Please login first.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load authentication data: ${e.toString()}'),
        ),
      );
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
      setState(() {
        _isLoadingBusinesses = false;
      });
      return;
    }

    setState(() {
      _isLoadingBusinesses = true;
    });

    try {
      final headers = _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_apiUrlBusinesses),
        headers: headers,
      );

      setState(() {
        _isLoadingBusinesses = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('businesses_data', response.body);

        setState(() {
          _businesses = data;
          if (_businesses.isNotEmpty) {
            _selectedBusinessId = _businesses[0]['id'];
          }
        });
      } else if (response.statusCode == 401) {
        _handleAuthError();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('businesses_data');
        if (cachedData != null) {
          setState(() {
            _businesses = json.decode(cachedData);
            if (_businesses.isNotEmpty) {
              _selectedBusinessId = _businesses[0]['id'];
            }
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load businesses: ${response.reasonPhrase}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingBusinesses = false;
      });

      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('businesses_data');
      if (cachedData != null) {
        setState(() {
          _businesses = json.decode(cachedData);
          if (_businesses.isNotEmpty) {
            _selectedBusinessId = _businesses[0]['id'];
          }
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: ${e.toString()}')));
    }
  }

  void _handleAuthError() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    setState(() {
      _authToken = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please log in again.'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    TimeOfDay initialTime =
        isStartTime
            ? TimeOfDay.fromDateTime(_startTime)
            : TimeOfDay.fromDateTime(_endTime);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = DateTime(
            _postDate.year,
            _postDate.month,
            _postDate.day,
            picked.hour,
            picked.minute,
          );
        } else {
          _endTime = DateTime(
            _postDate.year,
            _postDate.month,
            _postDate.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  void _addComplimentaryOption() {
    if (_newComplimentary.isNotEmpty) {
      setState(() {
        _complimentaryOptions.add(_newComplimentary);
        _selectedComplimentary.add(true);
        _newComplimentary = '';
        _newComplimentaryController.clear();
      });
    }
  }

  bool _validateTimeRange() {
    return _startTime.isBefore(_endTime);
  }

  bool _validateRates() {
    if (_showHourlyRate) {
      double? hourlyRate = double.tryParse(_hourlyRateController.text);
      if (hourlyRate == null || hourlyRate <= 0) return false;
    }

    if (_showPerDeliveryRate) {
      double? perDeliveryRate = double.tryParse(
        _perDeliveryRateController.text,
      );
      if (perDeliveryRate == null || perDeliveryRate <= 0) return false;
    }

    return true;
  }

  Future<void> _publishJobPosting() async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to post jobs')),
      );
      return;
    }

    if (_selectedBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business first')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form')),
      );
      return;
    }

    if (!_validateTimeRange()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    if (!_validateRates()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rates must be valid positive numbers')),
      );
      return;
    }

    final selectedBenefits =
        List.generate(
          _selectedComplimentary.length,
          (index) =>
              _selectedComplimentary[index]
                  ? _complimentaryOptions[index]
                  : null,
        ).where((item) => item != null).toList();

    final Map<String, dynamic> jobPostingData = {
      "business": _selectedBusinessId,
      "title": _titleController.text,
      "description": _selectedDescription,
      "post_date": DateFormat('yyyy-MM-dd').format(_postDate),
      "start_time": DateFormat('HH:mm:ss').format(_startTime),
      "end_time": DateFormat('HH:mm:ss').format(_endTime),
      "hourly_rate": _showHourlyRate ? _hourlyRateController.text : null,
      "per_delivery_rate":
          _showPerDeliveryRate ? _perDeliveryRateController.text : null,
      "complimentary_benefits": selectedBenefits,
      "created_at": DateTime.now().toUtc().toIso8601String(),
      "updated_at": DateTime.now().toUtc().toIso8601String(),
      "is_active": true,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final headers = _getAuthHeaders();
      final response = await http.post(
        Uri.parse(_apiUrlJobPosts),
        headers: headers,
        body: json.encode(jobPostingData),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        _showSuccessDialog(responseData);
      } else if (response.statusCode == 401) {
        _handleAuthError();
      } else {
        final errorData = json.decode(response.body);
        _showErrorDialog(errorData.toString());
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Network error: ${e.toString()}');
    }
  }

  void _showSuccessDialog(dynamic responseData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Job Posted Successfully!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: Text(
            'Your driver job posting has been published. The job shift is scheduled for ${DateFormat('MMMM d, yyyy').format(_postDate)} from ${DateFormat('h:mm a').format(_startTime)} to ${DateFormat('h:mm a').format(_endTime)}.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Error',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          content: Text(
            'Failed to post job: $errorMessage',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Create New Job',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body:
          _authToken == null
              ? _buildLoginPrompt(context)
              : _isLoading
              ? _buildLoadingIndicator()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Details
                      _buildSectionCard(
                        title: 'Job Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextFormField(
                              controller: _titleController,
                              label: 'Job Title',
                              icon: FontAwesomeIcons.briefcase,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a job title';
                                }
                                final wordCount =
                                    value.trim().split(RegExp(r'\s+')).length;
                                if (wordCount > 20) {
                                  return 'Job title must be 20 words or fewer';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildJobDescriptionSelector(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Schedule Settings
                      _buildSectionCard(
                        title: 'Schedule Settings',
                        child: Column(
                          children: [
                            _buildTextFormField(
                              controller: TextEditingController(
                                text: DateFormat(
                                  'MMMM d, yyyy',
                                ).format(_postDate),
                              ),
                              label: 'Job Date',
                              icon: FontAwesomeIcons.calendar,
                              readOnly: true,
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              controller: TextEditingController(
                                text: DateFormat('h:mm a').format(_startTime),
                              ),
                              label: 'Start Time',
                              icon: FontAwesomeIcons.clock,
                              readOnly: true,
                              onTap: () => _selectTime(context, true),
                            ),
                            const SizedBox(height: 12),
                            _buildTextFormField(
                              controller: TextEditingController(
                                text: DateFormat('h:mm a').format(_endTime),
                              ),
                              label: 'End Time',
                              icon: FontAwesomeIcons.clock,
                              readOnly: true,
                              onTap: () => _selectTime(context, false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rate Settings
                      _buildSectionCard(
                        title: 'Rate Settings',
                        child: Column(
                          children: [
                            _buildRateCheckbox(
                              label: 'Hourly Rate',
                              value: _showHourlyRate,
                              onChanged:
                                  (value) => setState(
                                    () => _showHourlyRate = value ?? false,
                                  ),
                            ),
                            if (_showHourlyRate) ...[
                              const SizedBox(height: 8),
                              _buildTextFormField(
                                controller: _hourlyRateController,
                                label: 'Hourly Rate (£)',
                                icon: FontAwesomeIcons.poundSign,
                                keyboardType: TextInputType.number,
                                validator:
                                    (value) =>
                                        _showHourlyRate &&
                                                (value == null || value.isEmpty)
                                            ? 'Please enter hourly rate'
                                            : _showHourlyRate &&
                                                double.tryParse(value!) == null
                                            ? 'Please enter a valid number'
                                            : null,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildRateCheckbox(
                              label: 'Per Delivery Rate',
                              value: _showPerDeliveryRate,
                              onChanged:
                                  (value) => setState(
                                    () => _showPerDeliveryRate = value ?? false,
                                  ),
                            ),
                            if (_showPerDeliveryRate) ...[
                              const SizedBox(height: 8),
                              _buildTextFormField(
                                controller: _perDeliveryRateController,
                                label: 'Per Delivery Rate (£)',
                                icon: FontAwesomeIcons.truck,
                                keyboardType: TextInputType.number,
                                validator:
                                    (value) =>
                                        _showPerDeliveryRate &&
                                                (value == null || value.isEmpty)
                                            ? 'Please enter per delivery rate'
                                            : _showPerDeliveryRate &&
                                                double.tryParse(value!) == null
                                            ? 'Please enter a valid number'
                                            : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Complimentary Benefits
                      _buildSectionCard(
                        title: 'Complimentary Benefits',
                        child: Column(
                          children: [
                            ...List.generate(_complimentaryOptions.length, (
                              index,
                            ) {
                              return _buildBenefitCheckbox(
                                label: _complimentaryOptions[index],
                                value: _selectedComplimentary[index],
                                onChanged:
                                    (value) => setState(
                                      () =>
                                          _selectedComplimentary[index] =
                                              value ?? false,
                                    ),
                              );
                            }),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextFormField(
                                    controller: _newComplimentaryController,
                                    label: 'Add New Benefit',
                                    icon: FontAwesomeIcons.plus,
                                    onChanged:
                                        (value) => setState(
                                          () => _newComplimentary = value,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildAddButton(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Publish Button
                      _buildPublishButton(),
                    ],
                  ),
                ),
              ),
    );
  }

  // Helper Widgets
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Please log in to create job postings',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Go to Login',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator(color: Colors.blue));
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    TextEditingController? controller,
    String? label,
    IconData? icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.black54,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        prefixIcon:
            icon != null
                ? Icon(icon, color: Colors.blue.shade600, size: 18)
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      validator: validator,
    );
  }

  Widget _buildJobDescriptionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Description',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(maxHeight: 180, minHeight: 80),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _jobDescriptions.length,
            itemBuilder: (context, index) {
              final description = _jobDescriptions[index];
              final isSelected =
                  _selectedDescription == description['description'];
              return GestureDetector(
                onTap:
                    () => setState(
                      () => _selectedDescription = description['description'],
                    ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.blue.shade600
                              : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description['title']!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected
                                        ? Colors.blue.shade600
                                        : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description['description']!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          FontAwesomeIcons.checkCircle,
                          color: Colors.blue.shade600,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRateCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue.shade600,
          checkColor: Colors.white,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue.shade600,
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: _addComplimentaryOption,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        'Add',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBusinessSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Business',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingBusinesses
            ? Container(
              height: 56,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue,
                ),
              ),
            )
            : _businesses.isEmpty
            ? Container(
              height: 56,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  'No businesses available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            )
            : DropdownButtonFormField<int>(
              value: _selectedBusinessId,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  FontAwesomeIcons.building,
                  color: Colors.blue.shade600,
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              items:
                  _businesses.map<DropdownMenuItem<int>>((business) {
                    return DropdownMenuItem<int>(
                      value: business['id'],
                      child: Text(
                        business['name'] ?? 'Unknown Business',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedBusinessId = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a business';
                }
                return null;
              },
            ),
      ],
    );
  }

  Widget _buildPublishButton() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _publishJobPosting,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            disabledBackgroundColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child:
              _isLoading
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Publishing...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        FontAwesomeIcons.paperPlane,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Publish Job Posting',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
