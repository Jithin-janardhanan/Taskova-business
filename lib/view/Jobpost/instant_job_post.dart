// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:animate_do/animate_do.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:taskova_shopkeeper/Model/api_config.dart';
// import 'package:taskova_shopkeeper/view/bottom_nav.dart';

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
//   final _hourlyRateController = TextEditingController(text: '15');
//   final _perDeliveryRateController = TextEditingController(text: '3');
//   final _newComplimentaryController = TextEditingController();

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

//   // Common job descriptions
//   final List<Map<String, String>> _jobDescriptions = [
//     {
//       'title': 'Delivery Driver',
//       'description':
//           'Responsible for timely delivery of goods to customers, maintaining vehicle condition, and ensuring accurate order fulfillment.',
//     },
//     {
//       'title': 'Courier Service',
//       'description':
//           'Handle package pickups and deliveries across designated routes, ensuring prompt and safe transport of items.',
//     },
//     {
//       'title': 'Food Delivery',
//       'description':
//           'Deliver food orders to customers efficiently, maintaining food quality and providing excellent customer service.',
//     },
//     {
//       'title': 'Freight Driver',
//       'description':
//           'Transport large shipments between locations, ensuring secure handling and adherence to delivery schedules.',
//     },
//   ];
//   String? _selectedDescription;

//   // API endpoints
//   final String _apiUrlBusinesses = (ApiConfig.businesses);
//   final String _apiUrlJobPosts = (ApiConfig.jobposts);

//   //   @override
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
//     _hourlyRateController.dispose();
//     _perDeliveryRateController.dispose();
//     _newComplimentaryController.dispose();
//     super.dispose();
//   }

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
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('')));
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
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('businesses_data', response.body);

//         setState(() {
//           _businesses = data;
//           if (_businesses.isNotEmpty) {
//             _selectedBusinessId = _businesses[0]['id'];
//           }
//         });
//       } else if (response.statusCode == 401) {
//         _handleAuthError();
//       } else {
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

//   void _handleAuthError() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('auth_token');

//     setState(() {
//       _authToken = null;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Your session has expired. Please log in again.'),
//         duration: Duration(seconds: 5),
//       ),
//     );
//   }

//   Future<void> _selectTime(BuildContext context, bool isStartTime) async {
//     TimeOfDay initialTime =
//         isStartTime
//             ? TimeOfDay.fromDateTime(_startTime)
//             : TimeOfDay.fromDateTime(_endTime);

//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: initialTime,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Colors.blue,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black87,
//             ),
//           ),
//           child: child!,
//         );
//       },
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
//         _newComplimentaryController.clear();
//       });
//     }
//   }

//   bool _validateTimeRange() {
//     return _startTime.isBefore(_endTime);
//   }

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

//     if (!_validateTimeRange()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('End time must be after start time')),
//       );
//       return;
//     }

//     if (!_validateRates()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Rates must be valid positive numbers')),
//       );
//       return;
//     }

//     final selectedBenefits =
//         List.generate(
//           _selectedComplimentary.length,
//           (index) =>
//               _selectedComplimentary[index]
//                   ? _complimentaryOptions[index]
//                   : null,
//         ).where((item) => item != null).toList();

//     final Map<String, dynamic> jobPostingData = {
//       "business": _selectedBusinessId,
//       "title": _titleController.text,
//       "description": _selectedDescription,
//       "job_date": DateFormat(
//         'yyyy-MM-dd',
//       ).format(_postDate), // Changed from "post_date"
//       "start_time": DateFormat('HH:mm:ss').format(_startTime),
//       "end_time": DateFormat('HH:mm:ss').format(_endTime),
//       "hourly_rate": _showHourlyRate ? _hourlyRateController.text : null,
//       "per_delivery_rate":
//           _showPerDeliveryRate ? _perDeliveryRateController.text : null,
//       "complimentary_benefits": selectedBenefits,
//       "status": "active", // Changed from "is_active": true
//     };

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final headers = _getAuthHeaders();
//       final response = await http.post(
//         Uri.parse(_apiUrlJobPosts),
//         headers: headers,
//         body: json.encode(jobPostingData),
//       );

//       setState(() {
//         _isLoading = false;
//       });

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = json.decode(response.body);
//         _showSuccessDialog(responseData);
//       } else if (response.statusCode == 401) {
//         _handleAuthError();
//       } else {
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
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           backgroundColor: Colors.white,
//           title: Text(
//             'Job Posted Successfully!',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//           content: Text(
//             'Your driver job posting has been published. The job shift is scheduled for ${DateFormat('MMMM d, yyyy').format(_postDate)} from ${DateFormat('h:mm a').format(_startTime)} to ${DateFormat('h:mm a').format(_endTime)}.',
//             style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pushAndRemoveUntil(
//                   MaterialPageRoute(
//                     builder: (context) => HomePageWithBottomNav(),
//                   ),
//                   (Route<dynamic> route) => false,
//                 );
//               },
//               child: Text(
//                 'OK',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.blue.shade600,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
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
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           backgroundColor: Colors.white,
//           title: Text(
//             'Form incomplete',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.red.shade600,
//             ),
//           ),
//           content: Text(
//             'Please Select description.',
//             style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text(
//                 'OK',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.blue.shade600,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: Text(
//           'Create New Job',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             fontSize: 18,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.blue.shade600,
//         foregroundColor: Colors.white,
//         elevation: 1,
//         centerTitle: true,
//       ),
//       body:
//           _authToken == null
//               ? _buildLoginPrompt(context)
//               : _isLoading
//               ? _buildLoadingIndicator()
//               : SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Job Details
//                       _buildSectionCard(
//                         title: 'Job Details',
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildTextFormField(
//                               controller: _titleController,
//                               label: 'Job Title',
//                               icon: FontAwesomeIcons.briefcase,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter a job title';
//                                 }
//                                 final wordCount =
//                                     value.trim().split(RegExp(r'\s+')).length;
//                                 if (wordCount > 20) {
//                                   return 'Job title must be 20 words or fewer';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 16),
//                             _buildJobDescriptionSelector(),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),

//                       // Schedule Settings
//                       _buildSectionCard(
//                         title: 'Working hours',
//                         child: Column(
//                           children: [
//                             _buildTextFormField(
//                               controller: TextEditingController(
//                                 text: DateFormat(
//                                   'MMMM d, yyyy',
//                                 ).format(_postDate),
//                               ),
//                               label: 'Job Date',
//                               icon: FontAwesomeIcons.calendar,
//                               readOnly: true,
//                             ),
//                             const SizedBox(height: 12),
//                             _buildTextFormField(
//                               controller: TextEditingController(
//                                 text: DateFormat('h:mm a').format(_startTime),
//                               ),
//                               label: 'Start Time',
//                               icon: FontAwesomeIcons.clock,
//                               readOnly: true,
//                               onTap: () => _selectTime(context, true),
//                             ),
//                             const SizedBox(height: 12),
//                             _buildTextFormField(
//                               controller: TextEditingController(
//                                 text: DateFormat('h:mm a').format(_endTime),
//                               ),
//                               label: 'End Time',
//                               icon: FontAwesomeIcons.clock,
//                               readOnly: true,
//                               onTap: () => _selectTime(context, false),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),

//                       // Rate Settings
//                       _buildSectionCard(
//                         title: 'Rate Settings',
//                         child: Column(
//                           children: [
//                             _buildRateCheckbox(
//                               label: 'Hourly Rate',
//                               value: _showHourlyRate,
//                               onChanged:
//                                   (value) => setState(
//                                     () => _showHourlyRate = value ?? false,
//                                   ),
//                             ),
//                             if (_showHourlyRate) ...[
//                               const SizedBox(height: 8),
//                               _buildTextFormField(
//                                 controller: _hourlyRateController,
//                                 label: 'Hourly Rate (£)',
//                                 icon: FontAwesomeIcons.poundSign,
//                                 keyboardType: TextInputType.number,
//                                 validator:
//                                     (value) =>
//                                         _showHourlyRate &&
//                                                 (value == null || value.isEmpty)
//                                             ? 'Please enter hourly rate'
//                                             : _showHourlyRate &&
//                                                 double.tryParse(value!) == null
//                                             ? 'Please enter a valid number'
//                                             : null,
//                               ),
//                             ],
//                             const SizedBox(height: 12),
//                             _buildRateCheckbox(
//                               label: 'Per Delivery Rate',
//                               value: _showPerDeliveryRate,
//                               onChanged:
//                                   (value) => setState(
//                                     () => _showPerDeliveryRate = value ?? false,
//                                   ),
//                             ),
//                             if (_showPerDeliveryRate) ...[
//                               const SizedBox(height: 8),
//                               _buildTextFormField(
//                                 controller: _perDeliveryRateController,
//                                 label: 'Per Delivery Rate (£)',
//                                 icon: FontAwesomeIcons.truck,
//                                 keyboardType: TextInputType.number,
//                                 validator:
//                                     (value) =>
//                                         _showPerDeliveryRate &&
//                                                 (value == null || value.isEmpty)
//                                             ? 'Please enter per delivery rate'
//                                             : _showPerDeliveryRate &&
//                                                 double.tryParse(value!) == null
//                                             ? 'Please enter a valid number'
//                                             : null,
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),

//                       // Complimentary Benefits
//                       _buildSectionCard(
//                         title: 'Complimentary Benefits',
//                         child: Column(
//                           children: [
//                             ...List.generate(_complimentaryOptions.length, (
//                               index,
//                             ) {
//                               return _buildBenefitCheckbox(
//                                 label: _complimentaryOptions[index],
//                                 value: _selectedComplimentary[index],
//                                 onChanged:
//                                     (value) => setState(
//                                       () =>
//                                           _selectedComplimentary[index] =
//                                               value ?? false,
//                                     ),
//                               );
//                             }),
//                             const SizedBox(height: 12),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _buildTextFormField(
//                                     controller: _newComplimentaryController,
//                                     label: 'Add New Benefit',
//                                     icon: FontAwesomeIcons.plus,
//                                     onChanged:
//                                         (value) => setState(
//                                           () => _newComplimentary = value,
//                                         ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 _buildAddButton(),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24),

//                       // Publish Button
//                       _buildPublishButton(),
//                     ],
//                   ),
//                 ),
//               ),
//     );
//   }

//   // Helper Widgets
//   Widget _buildLoginPrompt(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             'Please log in to create job postings',
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               color: Colors.black54,
//               fontWeight: FontWeight.w400,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               // Navigator.of(context).pushReplacementNamed('/login');
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade600,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             ),
//             child: Text(
//               'Go to Login',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.white,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return const Center(child: CircularProgressIndicator(color: Colors.blue));
//   }

//   Widget _buildSectionCard({required String title, required Widget child}) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 12),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _buildTextFormField({
//     TextEditingController? controller,
//     String? label,
//     IconData? icon,
//     TextInputType? keyboardType,
//     bool readOnly = false,
//     String? Function(String?)? validator,
//     Function(String)? onChanged,
//     VoidCallback? onTap,
//   }) {
//     return TextFormField(
//       controller: controller,
//       readOnly: readOnly,
//       keyboardType: keyboardType,
//       onChanged: onChanged,
//       onTap: onTap,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: GoogleFonts.poppins(
//           color: Colors.black54,
//           fontWeight: FontWeight.w400,
//           fontSize: 14,
//         ),
//         prefixIcon:
//             icon != null
//                 ? Icon(icon, color: Colors.blue.shade600, size: 18)
//                 : null,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.grey[50],
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 12,
//           vertical: 14,
//         ),
//       ),
//       style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
//       validator: validator,
//     );
//   }

//   Widget _buildJobDescriptionSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Job Description',
//           style: GoogleFonts.poppins(
//             fontSize: 14,
//             color: Colors.black54,
//             fontWeight: FontWeight.w400,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           constraints: BoxConstraints(maxHeight: 180, minHeight: 80),
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: _jobDescriptions.length,
//             itemBuilder: (context, index) {
//               final description = _jobDescriptions[index];
//               final isSelected =
//                   _selectedDescription == description['description'];
//               return GestureDetector(
//                 onTap:
//                     () => setState(
//                       () => _selectedDescription = description['description'],
//                     ),
//                 child: Container(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color:
//                           isSelected
//                               ? Colors.blue.shade600
//                               : Colors.grey.shade300,
//                       width: isSelected ? 2 : 1,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               description['title']!,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                                 color:
//                                     isSelected
//                                         ? Colors.blue.shade600
//                                         : Colors.black87,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               description['description']!,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 color: Colors.black54,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (isSelected)
//                         Icon(
//                           FontAwesomeIcons.checkCircle,
//                           color: Colors.blue.shade600,
//                           size: 18,
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRateCheckbox({
//     required String label,
//     required bool value,
//     required ValueChanged<bool?> onChanged,
//   }) {
//     return Row(
//       children: [
//         Checkbox(
//           value: value,
//           onChanged: onChanged,
//           activeColor: Colors.blue.shade600,
//           checkColor: Colors.white,
//           materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//         ),
//         Text(
//           label,
//           style: GoogleFonts.poppins(
//             fontSize: 14,
//             fontWeight: FontWeight.w400,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildBenefitCheckbox({
//     required String label,
//     required bool value,
//     required ValueChanged<bool?> onChanged,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           Checkbox(
//             value: value,
//             onChanged: onChanged,
//             activeColor: Colors.blue.shade600,
//             checkColor: Colors.white,
//             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//           ),
//           Expanded(
//             child: Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.black87,
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAddButton() {
//     return ElevatedButton(
//       onPressed: _addComplimentaryOption,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.blue.shade600,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//       child: Text(
//         'Add',
//         style: GoogleFonts.poppins(
//           fontSize: 14,
//           color: Colors.white,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }

//   Widget _buildPublishButton() {
//     return FadeInUp(
//       duration: const Duration(milliseconds: 600),
//       child: SizedBox(
//         width: double.infinity,
//         height: 50,
//         child: ElevatedButton(
//           onPressed: _isLoading ? null : _publishJobPosting,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue.shade600,
//             disabledBackgroundColor: Colors.grey.shade400,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             elevation: 2,
//           ),
//           child:
//               _isLoading
//                   ? Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Publishing...',
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   )
//                   : Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(
//                         FontAwesomeIcons.paperPlane,
//                         color: Colors.white,
//                         size: 18,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Publish Job Posting',
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//         ),
//       ),
//     );
//   }
// }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:taskova_shopkeeper/Model/api_config.dart';
// import 'package:taskova_shopkeeper/view/Jobpost/job_manage.dart';
// import 'package:taskova_shopkeeper/view/Jobpost/subscription.dart';
// import 'package:taskova_shopkeeper/view/Jobpost/mypost.dart';

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
//   int? _shopkeeperId;

//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _hourlyRateController = TextEditingController();
//   final _perDeliveryRateController = TextEditingController();

//   // Default to today for instant job posting
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

//   // Updated method to check instant job posting limits
//   Future<Map<String, dynamic>?> _checkInstantJobPostingLimits() async {
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
//                 'Failed to check instant job posting limits: ${response.statusCode}',
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
//             content: Text(
//               'Error checking instant job posting limits: ${e.toString()}',
//             ),
//           ),
//         );
//       }
//       return null;
//     }
//   }

//   Future<void> _checkSubscriptionAndProceed() async {
//     // First check the instant job creation API directly
//     final jobLimits = await _checkInstantJobPostingLimits();
//     if (jobLimits == null) return;

//     final status = jobLimits['status'];
//     final message = jobLimits['message'];
//     final limitPlanType = jobLimits['plan_type'];
//     final maxDailyPosts = jobLimits['max_daily_posts'] ?? 0;
//     final postsToday = jobLimits['posts_today'] ?? 0;

//     // Handle different plan types from instant job creation API
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

//     if (limitPlanType == 'BASIC') {
//       // Basic users - check daily posting limits
//       if (postsToday < maxDailyPosts) {
//         await _publishJobPosting();
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'You have reached your daily posting limit ($maxDailyPosts). You have posted $postsToday jobs today.',
//               ),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//       return;
//     }

//     if (limitPlanType == 'PREMIUM') {
//       // Premium users - check daily posting limits
//       if (postsToday < maxDailyPosts) {
//         await _publishJobPosting();
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'You have reached your daily posting limit ($maxDailyPosts). You have posted $postsToday jobs today.',
//               ),
//               backgroundColor: Colors.red,
//             ),
//           );
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

//       case 'BASIC':
//         // Basic users - check daily posting limits
//         if (limitPlanType == 'BASIC' && postsToday < maxDailyPosts) {
//           await _publishJobPosting();
//         } else if (limitPlanType == 'BASIC' && postsToday >= maxDailyPosts) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   'You have reached your daily posting limit ($maxDailyPosts). You have posted $postsToday jobs today.',
//                 ),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         } else {
//           await _publishJobPosting();
//         }
//         break;

//       case 'PREMIUM':
//         // Premium users - check daily posting limits
//         if (limitPlanType == 'PREMIUM' && postsToday < maxDailyPosts) {
//           await _publishJobPosting();
//         } else if (limitPlanType == 'PREMIUM' && postsToday >= maxDailyPosts) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   'You have reached your daily posting limit ($maxDailyPosts). You have posted $postsToday jobs today.',
//                 ),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         } else {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   message ?? 'Unable to verify daily posting limits.',
//                 ),
//                 backgroundColor: Colors.orange,
//               ),
//             );
//           }
//         }
//         break;

//       default:
//         // Unknown plan type
//         if (mounted) {
//           final shouldNavigate = await showDialog<bool>(
//             context: context,
//             barrierDismissible: false,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text('Subscription Required'),
//                 content: const Text('Please subscribe to post jobs.'),
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
//         return ['instant_job_posting', 'basic_messaging'].contains(feature);
//       default:
//         // Trial users get limited access
//         return ['trial_job_posting'].contains(feature);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_authToken == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Post Instant Job')),
//         body: const Center(
//           child: Text('Please log in to create instant job postings'),
//         ),
//       );
//     }

//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Post Instant Job')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Post Instant Job'),
//         backgroundColor: Colors.orange,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 // Info card showing this is for today
//                 Card(
//                   color: Colors.orange.shade50,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.info,
//                           color: Color.fromARGB(255, 152, 33, 7),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Instant job posting is for TODAY (${DateFormat('MMM d, yyyy').format(_postDate)})',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w500,
//                               color: Colors.orange,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
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
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       foregroundColor: Colors.white,
//                     ),
//                     child:
//                         _isLoading
//                             ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   Colors.white,
//                                 ),
//                               ),
//                             )
//                             : const Text(
//                               'POST INSTANT JOB',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
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
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/Model/colors.dart';
import 'package:taskova_shopkeeper/view/Jobpost/job_manage.dart';
import 'package:taskova_shopkeeper/view/Jobpost/subscription.dart';
import 'package:taskova_shopkeeper/view/Jobpost/mypost.dart';

class InstatJobPost extends StatefulWidget {
  const InstatJobPost({super.key});

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
  int? _shopkeeperId;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _perDeliveryRateController = TextEditingController();

  // Complimentary benefits
  final List<String> _availableBenefits = [
    'Free Meals',
    'Transportation',
    'Flexible Hours',
    'Training Provided',
    'Bonus Incentives',
    'Uniform Provided',
    'Parking Available',
    'Staff Discounts',
    'Health Insurance',
    'Overtime Pay',
    'Tips Included',
    'Weekend Bonus',
  ];

  List<String> _selectedBenefits = [];

  // Description options
  final List<String> _descriptionOptions = [
    'Looking for reliable delivery personnel',
    'Need experienced kitchen staff',
    'Seeking friendly customer service representatives',
    'Hiring part-time cashiers',
    'Need skilled baristas',
    'Looking for warehouse workers',
    'Seeking cleaning staff',
    'Need retail sales associates',
    'Hiring food preparation staff',
    'Looking for security personnel',
    'Need maintenance workers',
    'Seeking administrative assistants',
  ];

  // Default to today for instant job posting
  DateTime _postDate = DateTime.now();
  DateTime _startTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    9,
    0,
  );
  DateTime _endTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    17,
    0,
  );

  bool _showHourlyRate = true;
  bool _showPerDeliveryRate = true;

  final String _apiUrlBusinesses = ApiConfig.businesses;
  final String _apiUrlJobPosts = ApiConfig.jobposts;

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
    _descriptionController.dispose();
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
          SnackBar(content: Text('Failed to load token: ${e.toString()}')),
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
              content: Text(
                'Failed to fetch businesses: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching businesses: ${e.toString()}')),
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
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              secondary: AppColors.secondaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
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

  void _showDescriptionOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Select Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _descriptionOptions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(_descriptionOptions[index]),
                        onTap: () {
                          _descriptionController.text =
                              _descriptionOptions[index];
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBenefitsSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.card_giftcard, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Select Benefits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _availableBenefits.length,
                      itemBuilder: (context, index) {
                        final benefit = _availableBenefits[index];
                        final isSelected = _selectedBenefits.contains(benefit);

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                _selectedBenefits.remove(benefit);
                              } else {
                                _selectedBenefits.add(benefit);
                              }
                            });
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primaryBlue
                                        : AppColors.mediumGray,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                benefit,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : AppColors.darkText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _publishJobPosting() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate time selection
    if (_startTime.isAfter(_endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Start time must be before end time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final jobPostingData = {
      "business": _selectedBusinessId,
      "title": _titleController.text,
      "description": _descriptionController.text,
      "job_date": DateFormat('yyyy-MM-dd').format(_postDate),
      "start_time": DateFormat('HH:mm:ss').format(_startTime),
      "end_time": DateFormat('HH:mm:ss').format(_endTime),
      "hourly_rate": _showHourlyRate ? _hourlyRateController.text : null,
      "per_delivery_rate":
          _showPerDeliveryRate ? _perDeliveryRateController.text : null,
      "complimentary_benefits": _selectedBenefits,
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
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchSubscriptionStatus(
    int shopkeeperId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/subscriptions/current/?shopkeeper_id=$shopkeeperId',
      );
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to fetch subscription status: ${response.statusCode}',
              ),
              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _checkInstantJobPostingLimits() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/job-posts/create/');
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to check instant job posting limits: ${response.statusCode}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error checking instant job posting limits: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _checkSubscriptionAndProceed() async {
    final jobLimits = await _checkInstantJobPostingLimits();
    if (jobLimits == null) return;

    final status = jobLimits['status'];
    final message = jobLimits['message'];
    final limitPlanType = jobLimits['plan_type'];
    final maxDailyPosts = jobLimits['max_daily_posts'] ?? 0;
    final postsToday = jobLimits['posts_today'] ?? 0;

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Subscription Required',
                style: TextStyle(color: AppColors.darkText),
              ),
              content: Text(
                message ??
                    'You currently have no active trial or subscription. Please subscribe to post jobs.',
                style: TextStyle(color: AppColors.darkText),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );

        if (shouldNavigate == true) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionPlansPage(),
            ),
          );

          if (result == true) {
            await _checkSubscriptionAndProceed();
          }
        }
      }
      return;
    }

    if (limitPlanType == 'BASIC') {
      if (postsToday < maxDailyPosts) {
        await _publishJobPosting();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have reached your daily posting limit ($maxDailyPosts). You have posted $postsToday jobs today.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    if (limitPlanType == 'PREMIUM') {
      if (postsToday < maxDailyPosts) {
        await _publishJobPosting();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have reached your daily posting limit ($maxDailyPosts). You have posted $postsToday jobs today.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Fallback for other plan types
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
      case 'BASIC':
        if (limitPlanType == 'BASIC' && postsToday < maxDailyPosts) {
          await _publishJobPosting();
        } else if (limitPlanType == 'BASIC' && postsToday >= maxDailyPosts) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You have reached your daily posting limit ($maxDailyPosts). You have posted $postsToday jobs today.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          await _publishJobPosting();
        }
        break;
      case 'PREMIUM':
        if (limitPlanType == 'PREMIUM' && postsToday < maxDailyPosts) {
          await _publishJobPosting();
        } else if (limitPlanType == 'PREMIUM' && postsToday >= maxDailyPosts) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You have reached your daily posting limit ($maxDailyPosts). You have posted $postsToday jobs today.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message ?? 'Unable to verify daily posting limits.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        break;
      default:
        if (mounted) {
          final shouldNavigate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  'Subscription Required',
                  style: TextStyle(color: AppColors.darkText),
                ),
                content: const Text('Please subscribe to post jobs.'),
                actions: [
                  TextButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          );

          if (shouldNavigate == true) {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionPlansPage(),
              ),
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
        return ['instant_job_posting', 'basic_messaging'].contains(feature);
      default:
        return ['trial_job_posting'].contains(feature);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authToken == null) {
      return Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: AppBar(
          title: const Text('Post Instant Job'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to create instant job postings'),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: AppBar(
          title: const Text('Post Instant Job'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Post Instant Job'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.secondaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Instant job for TODAY (${DateFormat('MMM d, yyyy').format(_postDate)})',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Business Selection
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(8),
              //     boxShadow: [
              //       BoxShadow(
              //         color: AppColors.mediumGray.withOpacity(0.3),
              //         blurRadius: 4,
              //         offset: const Offset(0, 2),
              //       ),
              //     ],
              //   ),
              //   child: Padding(
              //     padding: const EdgeInsets.all(12),
              //     child:
              //         _isLoadingBusinesses
              //             ? Center(
              //               child: CircularProgressIndicator(
              //                 valueColor: AlwaysStoppedAnimation<Color>(
              //                   AppColors.primaryBlue,
              //                 ),
              //               ),
              //             )
              //             : _businesses.isNotEmpty
              //             ? DropdownButtonFormField<int>(
              //               decoration: InputDecoration(
              //                 labelText: 'Business',
              //                 labelStyle: TextStyle(
              //                   color: AppColors.primaryBlue,
              //                 ),
              //                 border: OutlineInputBorder(
              //                   borderRadius: BorderRadius.circular(8),
              //                   borderSide: BorderSide(
              //                     color: AppColors.mediumGray,
              //                   ),
              //                 ),
              //                 focusedBorder: OutlineInputBorder(
              //                   borderRadius: BorderRadius.circular(8),
              //                   borderSide: BorderSide(
              //                     color: Ap,   xdswxcdw cdw cdvrwccdwcdcd wcsdwxsxcedw3vrvfcwc dwcdcddwxspColo[  s.primaryBlue,
              //                   ),
              //                 ),
              //                 contentPadding: const EdgeInsets.symmetric(
              //                   horizontal: 12,
              //                   vertical: 8,
              //                 ),
              //               ),
              //               value: _selectedBusinessId,
              //               items:
              //                   _businesses.map((business) {
              //                     return DropdownMenuItem<int>(
              //                       value: business['id'],
              //                       child: Text(
              //                         business['name'] ?? 'Unknown Business',
              //                         style: TextStyle(
              //                           color: AppColors.darkText,
              //                         ),
              //                       ),
              //                     );
              //                   }).toList(),
              //               onChanged: (value) {
              //                 setState(() {
              //                   _selectedBusinessId = value;
              //                 });
              //               },
              //               validator:
              //                   (value) =>
              //                       value == null
              //                           ? 'Please select a business'
              //                           : null,
              //             )
              //             : Text(
              //               'No businesses available',
              //               style: TextStyle(color: AppColors.darkText),
              //             ),
              //   ),
              // ),
              // const SizedBox(height: 12),

              // Job Title
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mediumGray.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    controller: _titleController,
                    maxLength: 30,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                    decoration: InputDecoration(
                      labelText: 'Job Title',
                      labelStyle: TextStyle(color: AppColors.primaryBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.mediumGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      counterStyle: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Please enter a job title'
                                : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mediumGray.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: AppColors.primaryBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.mediumGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Please enter a description'
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showDescriptionOptions,
                          icon: Icon(
                            Icons.list,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                          label: Text(
                            'Choose from templates',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Time Selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mediumGray.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppColors.primaryBlue,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Time',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('h:mm a').format(_startTime),
                                      style: TextStyle(
                                        color: AppColors.darkText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppColors.primaryBlue,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Time',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('h:mm a').format(_endTime),
                                      style: TextStyle(
                                        color: AppColors.darkText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
              const SizedBox(height: 12),

              // Rate Fields
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mediumGray.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (_showHourlyRate)
                        TextFormField(
                          controller: _hourlyRateController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Hourly Rate (£)',
                            labelStyle: TextStyle(color: AppColors.primaryBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.mediumGray,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            prefixIcon: Icon(
                              Icons.monetization_on,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          validator: (value) {
                            if (_showHourlyRate &&
                                (value == null || value.isEmpty)) {
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
                      if (_showHourlyRate && _showPerDeliveryRate)
                        const SizedBox(height: 12),
                      if (_showPerDeliveryRate)
                        TextFormField(
                          controller: _perDeliveryRateController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Per Delivery Rate (£)',
                            labelStyle: TextStyle(color: AppColors.primaryBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.mediumGray,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            prefixIcon: Icon(
                              Icons.local_shipping,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          validator: (value) {
                            if (_showPerDeliveryRate &&
                                (value == null || value.isEmpty)) {
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
              const SizedBox(height: 12),

              // Benefits Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mediumGray.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Complimentary Benefits',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedBenefits.isEmpty)
                        Text(
                          'No benefits selected',
                          style: TextStyle(
                            color: AppColors.darkText.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              _selectedBenefits.map((benefit) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    benefit,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showBenefitsSelection,
                          icon: Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                          label: Text(
                            'Add Benefits',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkSubscriptionAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'POST INSTANT JOB',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
