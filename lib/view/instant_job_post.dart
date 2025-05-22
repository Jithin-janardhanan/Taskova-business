import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';

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

  // Form controllers
  final _titleController = TextEditingController(text: 'Drivers Needed TODAY!');
  final _descriptionController = TextEditingController(text: '');
  final _hourlyRateController = TextEditingController(text: '15');
  final _perDeliveryRateController = TextEditingController(text: '3');

  // Form values - Using today's date
  final DateTime _postDate = DateTime.now();
  late DateTime _startTime;
  late DateTime _endTime;
  bool _showHourlyRate = true;
  bool _showPerDeliveryRate = true;
  final List<String> _complimentaryOptions = [
    'Meal during shift',
    'Free drinks',
    'Fuel allowance',
  ];
  final List<bool> _selectedComplimentary = [true, false, false];
  String _newComplimentary = '';

  // API endpoints
  final String _apiUrlBusinesses = (ApiConfig.businesses);
  final String _apiUrlJobPosts = (ApiConfig.jobposts);

  @override
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

   

    // Create job posting data
    final Map<String, dynamic> jobPostingData = {
      "business": _selectedBusinessId,
      "title": _titleController.text,
      "description": _descriptionController.text,
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
      appBar: AppBar(title: const Text('Create Driver Job Posting')),
      body:
          _authToken == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Please log in to create job postings',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to login page
                        // Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              )
              : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business selection card
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Business',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _isLoadingBusinesses
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _businesses.isEmpty
                                  ? const Text('No businesses found')
                                  : DropdownButtonFormField<int>(
                                    decoration: const InputDecoration(
                                      labelText: 'Business',
                                      border: OutlineInputBorder(),
                                      filled: true,
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
                            ],
                          ),
                        ),
                      ),

                      // Job Posting Details card
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Job Posting Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Job Title',
                                  border: OutlineInputBorder(),
                                  filled: true,
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
                                decoration: const InputDecoration(
                                  labelText: 'Job Description',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                ),
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a job description';
                                  }
                                  
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Schedule Settings card
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Schedule Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                title: const Text('Job Date'),
                                subtitle: Text(
                                  DateFormat('MMMM d, yyyy').format(_postDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: const Icon(Icons.calendar_today),
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Start Time'),
                                subtitle: Text(
                                  DateFormat('h:mm a').format(_startTime),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: const Icon(Icons.access_time),
                                onTap: () => _selectTime(context, true),
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('End Time'),
                                subtitle: Text(
                                  DateFormat('h:mm a').format(_endTime),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: const Icon(Icons.access_time),
                                onTap: () => _selectTime(context, false),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Payment Information card
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                title: const Text('Include Hourly Rate'),
                                value: _showHourlyRate,
                                onChanged: (value) {
                                  setState(() {
                                    _showHourlyRate = value ?? true;
                                  });
                                },
                              ),
                              if (_showHourlyRate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: TextFormField(
                                    controller: _hourlyRateController,
                                    decoration: const InputDecoration(
                                      labelText: 'Hourly Rate (£)',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      prefixIcon: Icon(Icons.attach_money),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (_showHourlyRate &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please enter an hourly rate';
                                      }
                                      if (_showHourlyRate) {
                                        double? rate = double.tryParse(value!);
                                        if (rate == null) {
                                          return 'Please enter a valid number';
                                        }
                                        if (rate <= 0) {
                                          return 'Rate must be greater than zero';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              const Divider(),
                              CheckboxListTile(
                                title: const Text('Include Per Delivery Rate'),
                                value: _showPerDeliveryRate,
                                onChanged: (value) {
                                  setState(() {
                                    _showPerDeliveryRate = value ?? true;
                                  });
                                },
                              ),
                              if (_showPerDeliveryRate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: TextFormField(
                                    controller: _perDeliveryRateController,
                                    decoration: const InputDecoration(
                                      labelText: 'Per Delivery Rate (£)',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      prefixIcon: Icon(Icons.local_shipping),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (_showPerDeliveryRate &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please enter a per delivery rate';
                                      }
                                      if (_showPerDeliveryRate) {
                                        double? rate = double.tryParse(value!);
                                        if (rate == null) {
                                          return 'Please enter a valid number';
                                        }
                                        if (rate <= 0) {
                                          return 'Rate must be greater than zero';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Complimentary Benefits card
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Complimentary Benefits',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(
                                _complimentaryOptions.length,
                                (index) => CheckboxListTile(
                                  title: Text(_complimentaryOptions[index]),
                                  value: _selectedComplimentary[index],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedComplimentary[index] =
                                          value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Add New Benefit',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _newComplimentary = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle),
                                    color: Theme.of(context).primaryColor,
                                    iconSize: 36,
                                    onPressed: _addComplimentaryOption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _publishJobPosting,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'PUBLISH JOB POSTING',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }
}
