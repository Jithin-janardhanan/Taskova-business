import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/Model/colors.dart';

// Add this package for better calendar

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
  bool _showCalendar = false; // Control visibility of calendar widget

  // Form controllers
  final _titleController = TextEditingController(text: 'Drivers Needed TODAY!');
  final _descriptionController = TextEditingController(text: '');
  final _hourlyRateController = TextEditingController(text: '15');
  final _perDeliveryRateController = TextEditingController(text: '3');

  // Form values
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
  final List<String> _complimentaryOptions = [
    'Meal during shift',
    'Free drinks',
    'Fuel allowance',
  ];
  final List<bool> _selectedComplimentary = [true, false, false];
  String _newComplimentary = '';

  // For date range limitation
  late DateTime _firstDay;
  late DateTime _lastDay;

  // API endpoints
  final String _apiUrlBusinesses = (ApiConfig.businesses);
  final String _apiUrlJobPosts = (ApiConfig.jobposts);

  @override
  void initState() {
    super.initState();
    _loadToken().then((_) => _fetchBusinesses());

    // Initialize date range (today to 7 days from now)
    _firstDay = DateTime.now();
    _lastDay = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _perDeliveryRateController.dispose();
    super.dispose();
  }

  // Load authentication token
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
        // Navigate back or to login page if needed
        // Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load authentication data: ${e.toString()}'),
        ),
      );
    }
  }

  // Create authorization header with token
  Map<String, String> _getAuthHeaders() {
    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  // Fetch businesses from API
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

        // Save businesses data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('businesses_data', response.body);

        setState(() {
          _businesses = data;
          // Select the first business by default if available
          if (_businesses.isNotEmpty) {
            _selectedBusinessId = _businesses[0]['id'];
          }
        });
      } else if (response.statusCode == 401) {
        // Token might be expired - handle authentication error
        _handleAuthError();
      } else {
        // Try to load from cached data if API call fails
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

      // Try to load from cached data if error occurs
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

  // Handle authentication errors
  void _handleAuthError() async {
    // Clear auth token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    setState(() {
      _authToken = null;
    });

    // Show message to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please log in again.'),
        duration: Duration(seconds: 5),
      ),
    );

    // Navigate to login page
    // Navigator.of(context).pushReplacementNamed('/login');
  }

  // New method to set today's date
  void _setTodayDate() {
    setState(() {
      _postDate = DateTime.now();

      // Update start and end times to maintain the same hours on today's date
      _startTime = DateTime(
        _postDate.year,
        _postDate.month,
        _postDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      _endTime = DateTime(
        _postDate.year,
        _postDate.month,
        _postDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Hide calendar widget
      _showCalendar = false;
    });
  }

  // Toggle calendar visibility
  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
    });
  }

  // Method to handle date selection from calendar
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Check if date is within allowed range (today to 7 days from now)
    final today = DateTime.now();
    final maxDate = today.add(const Duration(days: 7));

    if (selectedDay.isBefore(today) || selectedDay.isAfter(maxDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date must be within 7 days from today')),
      );
      return;
    }

    setState(() {
      _postDate = selectedDay;

      // Update start and end times to maintain the same hours on the new date
      _startTime = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        _startTime.hour,
        _startTime.minute,
      );

      _endTime = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Hide calendar after selection
      _showCalendar = false;
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    TimeOfDay initialTime =
        isStartTime
            ? TimeOfDay.fromDateTime(_startTime)
            : TimeOfDay.fromDateTime(_endTime);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
      });
    }
  }

  // Validate time range
  bool _validateTimeRange() {
    return _startTime.isBefore(_endTime);
  }

  // Validate rates
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

    // Additional validation for time range
    if (!_validateTimeRange()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    // Additional validation for rates
    if (!_validateRates()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rates must be valid positive numbers')),
      );
      return;
    }

    // At least one selected benefit
    final selectedBenefits =
        List.generate(
          _selectedComplimentary.length,
          (index) =>
              _selectedComplimentary[index]
                  ? _complimentaryOptions[index]
                  : null,
        ).where((item) => item != null).toList();

    if (selectedBenefits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one benefit')),
      );
      return;
    }

    // Create job posting data
    final Map<String, dynamic> jobPostingData = {
      "business": _selectedBusinessId,
      "title": _titleController.text,
      "description": _descriptionController.text,
      "job_date": DateFormat('yyyy-MM-dd').format(_postDate),
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

      // API call
      final response = await http.post(
        Uri.parse(_apiUrlJobPosts),
        headers: headers,
        body: json.encode(jobPostingData),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        final responseData = json.decode(response.body);
        _showSuccessDialog(responseData);
      } else if (response.statusCode == 401) {
        // Handle authentication error
        _handleAuthError();
      } else {
        // Error handling
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
          title: const Text('Job Posted Successfully!'),
          content: Text(
            'Your driver job posting has been published. The job shift is scheduled for ${DateFormat('MMMM d, yyyy').format(_postDate)} from ${DateFormat('h:mm a').format(_startTime)} to ${DateFormat('h:mm a').format(_endTime)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
          title: const Text('Error'),
          content: Text('Failed to post job: $errorMessage'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Driver Job Posting'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.lightGray,
      body:
          _authToken == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Please log in to create job postings',
                      style: TextStyle(fontSize: 18, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to login page
                        // Navigator.of(context).pushReplacementNamed('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              )
              : _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.lightBlue.withOpacity(0.3),
                      AppColors.lightGray,
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section title
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Text(
                            'Create New Driver Job',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),

                        // Business selection card
                        _buildCard(
                          title: 'Select Business',
                          icon: Icons.business,
                          color: AppColors.primaryBlue,
                          content:
                              _isLoadingBusinesses
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _businesses.isEmpty
                                  ? const Text('No businesses found')
                                  : DropdownButtonFormField<int>(
                                    decoration: InputDecoration(
                                      labelText: 'Business',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: AppColors.primaryBlue,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColors.primaryBlue,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    value: _selectedBusinessId,
                                    items:
                                        _businesses.map((business) {
                                          return DropdownMenuItem<int>(
                                            value: business['id'],
                                            child: Text(business['name']),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedBusinessId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a business';
                                      }
                                      return null;
                                    },
                                  ),
                        ),

                        // Job Posting Details card
                        _buildCard(
                          title: 'Job Posting Details',
                          icon: Icons.work,
                          color: AppColors.secondaryBlue,
                          content: Column(
                            children: [
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'Job Title',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: AppColors.secondaryBlue,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.title,
                                    color: AppColors.secondaryBlue,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a job title';
                                  }
                                  if (value.length < 5) {
                                    return 'Title must be at least 5 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: 'Job Description',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: AppColors.secondaryBlue,
                                  ),
                                  alignLabelWithHint: true,
                                  prefixIcon: Icon(
                                    Icons.description,
                                    color: AppColors.secondaryBlue,
                                  ),
                                ),
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a job description';
                                  }
                                  if (value.length < 20) {
                                    return 'Description must be at least 20 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        // Schedule Settings card
                        _buildCard(
                          title: 'Schedule Settings',
                          icon: Icons.schedule,
                          color: AppColors.accentGreen,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date selection with "Today" option
                              Row(
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      title: const Text('Job Date'),
                                      subtitle: Text(
                                        DateFormat(
                                          'MMMM d, yyyy',
                                        ).format(_postDate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.calendar_today,
                                        color: AppColors.accentGreen,
                                      ),
                                      onTap: _toggleCalendar,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _setTodayDate,
                                    icon: Icon(
                                      Icons.today,
                                      color: AppColors.accentGreen,
                                    ),
                                    label: Text(
                                      'Today',
                                      style: TextStyle(
                                        color: AppColors.accentGreen,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          isToday(_postDate)
                                              ? AppColors.softMint
                                              : Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Calendar widget (visible only when needed)
                              if (_showCalendar)
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.mediumGray,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: TableCalendar(
                                    firstDay: _firstDay,
                                    lastDay: _lastDay,
                                    focusedDay: _postDate,
                                    selectedDayPredicate:
                                        (day) => isSameDay(day, _postDate),
                                    onDaySelected: _onDaySelected,
                                    calendarFormat: CalendarFormat.week,
                                    availableCalendarFormats: const {
                                      CalendarFormat.week: 'Week',
                                      CalendarFormat.month: 'Month',
                                    },
                                    headerStyle: HeaderStyle(
                                      formatButtonTextStyle: TextStyle(
                                        color: AppColors.accentGreen,
                                      ),
                                      formatButtonDecoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.accentGreen,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      titleTextStyle: TextStyle(
                                        color: AppColors.darkText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      leftChevronIcon: Icon(
                                        Icons.chevron_left,
                                        color: AppColors.accentGreen,
                                      ),
                                      rightChevronIcon: Icon(
                                        Icons.chevron_right,
                                        color: AppColors.accentGreen,
                                      ),
                                    ),
                                    calendarStyle: CalendarStyle(
                                      todayDecoration: BoxDecoration(
                                        color: AppColors.accentGreen
                                            .withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      selectedDecoration: BoxDecoration(
                                        color: AppColors.accentGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      weekendTextStyle: TextStyle(
                                        color: AppColors.warmOrange,
                                      ),
                                    ),
                                  ),
                                ),

                              const Divider(color: AppColors.mediumGray),
                              _buildTimeSelector(
                                title: 'Start Time',
                                time: _startTime,
                                icon: Icons.play_circle_fill,
                                onTap: () => _selectTime(context, true),
                              ),
                              const Divider(color: AppColors.mediumGray),
                              _buildTimeSelector(
                                title: 'End Time',
                                time: _endTime,
                                icon: Icons.stop_circle,
                                onTap: () => _selectTime(context, false),
                              ),

                              // Helper text
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.softMint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: AppColors.accentGreen,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'You can select dates up to 7 days from today',
                                          style: TextStyle(
                                            color: AppColors.darkText,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Payment Information card
                        _buildCard(
                          title: 'Payment Information',
                          icon: Icons.payments,
                          color: AppColors.warmOrange,
                          content: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Include Hourly Pay'),
                                value: _showHourlyRate,
                                activeColor: AppColors.warmOrange,
                                onChanged: (value) {
                                  setState(() {
                                    _showHourlyRate = value;
                                  });
                                },
                              ),
                              if (_showHourlyRate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: TextFormField(
                                    controller: _hourlyRateController,
                                    decoration: InputDecoration(
                                      labelText: 'Hourly Pay (£)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: Icon(
                                        Icons.attach_money,
                                        color: AppColors.warmOrange,
                                      ),
                                      labelStyle: TextStyle(
                                        color: AppColors.warmOrange,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (_showHourlyRate &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please enter an hourly Pay';
                                      }
                                      if (_showHourlyRate) {
                                        double? rate = double.tryParse(value!);
                                        if (rate == null) {
                                          return 'Please enter a valid number';
                                        }
                                        if (rate <= 0) {
                                          return 'Pay must be greater than zero';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              const Divider(color: AppColors.mediumGray),
                              SwitchListTile(
                                title: const Text('Include Per Delivery Pay'),
                                value: _showPerDeliveryRate,
                                activeColor: AppColors.warmOrange,
                                onChanged: (value) {
                                  setState(() {
                                    _showPerDeliveryRate = value;
                                  });
                                },
                              ),
                              if (_showPerDeliveryRate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: TextFormField(
                                    controller: _perDeliveryRateController,
                                    decoration: InputDecoration(
                                      labelText: 'Per Delivery Pay (£)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: Icon(
                                        Icons.local_shipping,
                                        color: AppColors.warmOrange,
                                      ),
                                      labelStyle: TextStyle(
                                        color: AppColors.warmOrange,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (_showPerDeliveryRate &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please enter a per delivery Pay';
                                      }
                                      if (_showPerDeliveryRate) {
                                        double? rate = double.tryParse(value!);
                                        if (rate == null) {
                                          return 'Please enter a valid number';
                                        }
                                        if (rate <= 0) {
                                          return 'Pay must be greater than zero';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Complimentary Benefits card
                        _buildCard(
                          title: 'Complimentary Benefits',
                          icon: Icons.card_giftcard,
                          color: Colors.purple.shade400,
                          content: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.softPurple.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: List.generate(
                                    _complimentaryOptions.length,
                                    (index) => CheckboxListTile(
                                      title: Text(_complimentaryOptions[index]),
                                      value: _selectedComplimentary[index],
                                      activeColor: Colors.purple.shade400,
                                      checkColor: Colors.white,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedComplimentary[index] =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                color: AppColors.mediumGray,
                                height: 32,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Add New Benefit',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color: Colors.purple.shade400,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _newComplimentary = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.purple.shade100,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add),
                                      color: Colors.purple.shade700,
                                      iconSize: 28,
                                      onPressed: _addComplimentaryOption,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _publishJobPosting,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.published_with_changes, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'PUBLISH JOB POSTING',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // Helper method to build consistent cards
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom header with icon
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Content with padding
          Padding(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  // Helper method for time selectors
  Widget _buildTimeSelector({
    required String title,
    required DateTime time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        DateFormat('h:mm a').format(time),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.accentGreen),
      ),
      trailing: Icon(Icons.access_time, color: AppColors.accentGreen),
      onTap: onTap,
    );
  }

  // Helper method to check if a date is today
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
