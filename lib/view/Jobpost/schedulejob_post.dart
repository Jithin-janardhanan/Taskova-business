import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/view/Jobpost/subscription.dart';
import 'package:taskova_shopkeeper/view/mypost.dart';

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
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController(text: '15');
  final _perDeliveryRateController = TextEditingController(text: '3');

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _postDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (picked != null && mounted) {
      setState(() {
        _postDate = picked;
        _startTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startTime.hour,
          _startTime.minute,
        );
        _endTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _endTime.hour,
          _endTime.minute,
        );
      });
    }
  }

  Future<void> _publishJobPosting() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate time selection
    if (_startTime.isAfter(_endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be before end time')),
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
          // Use pushReplacement to prevent going back to this screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MyJobpost()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to post job: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
      // Handle error silently or log it
      debugPrint('Error fetching shopkeeper profile: $e');
    }
  }

  Future<int?> _fetchShopkeeperProfileId() async {
    // Return stored ID if available
    if (_shopkeeperId != null) {
      return _shopkeeperId;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/profile/');
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profileId = data['personal_profile']?['id'];

        // Store the ID for future use
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
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
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
          ),
        );
      }
      return null;
    }
  }

  // Future<void> _checkSubscriptionAndProceed() async {
  //   // Use stored shopkeeper ID or fetch it
  //   int? shopkeeperId = _shopkeeperId;

  //   if (shopkeeperId == null) {
  //     shopkeeperId = await _fetchShopkeeperProfileId();
  //     if (shopkeeperId == null) return;
  //   }

  //   final subscription = await _fetchSubscriptionStatus(shopkeeperId);
  //   if (subscription == null) return;

  //   final isTrial = subscription['is_trial'] ?? false;
  //   final status = subscription['status'] ?? '';

  //   if (isTrial || (status != "NO_SUBSCRIPTION")) {
  //     await _publishJobPosting();
  //   } else if (status == "NO_SUBSCRIPTION") {
  //     if (mounted) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => SubscriptionPlansPage(),
  //       ));
  //     }
  //   } else {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Subscription status unknown.')),
  //       );
  //     }
  //   }
  // }

  Future<void> _checkSubscriptionAndProceed() async {
  // Use stored shopkeeper ID or fetch it
  int? shopkeeperId = _shopkeeperId;

  if (shopkeeperId == null) {
    shopkeeperId = await _fetchShopkeeperProfileId();
    if (shopkeeperId == null) return;
  }

  final subscription = await _fetchSubscriptionStatus(shopkeeperId);
  if (subscription == null) return;

  final isTrial = subscription['is_trial'] ?? false;
  final status = subscription['status'] ?? '';

  if (isTrial || (status != "NO_SUBSCRIPTION")) {
    await _publishJobPosting();
  } else if (status == "NO_SUBSCRIPTION") {
    if (mounted) {
      // Navigate to subscription page and wait for result
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const SubscriptionPlansPage(),
        ),
      );

      // If user successfully subscribed, proceed with job posting
      if (result == true) {
        await _publishJobPosting();
      }
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription status unknown.')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_authToken == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Job Post')),
        body: const Center(child: Text('Please log in to create job postings')),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Job Post')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Job Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_isLoadingBusinesses)
                  const CircularProgressIndicator()
                else if (_businesses.isNotEmpty)
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Business'),
                    value: _selectedBusinessId,
                    items:
                        _businesses.map((business) {
                          return DropdownMenuItem<int>(
                            value: business['id'],
                            child: Text(business['name'] ?? 'Unknown Business'),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBusinessId = value;
                      });
                    },
                    validator:
                        (value) =>
                            value == null ? 'Please select a business' : null,
                  )
                else
                  const Text('No businesses available'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Job Title'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Please enter a job title'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Please enter a description'
                              : null,
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: Text(
                      'Date: ${DateFormat('MMM d, yyyy').format(_postDate)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: ListTile(
                          title: Text(
                            'Start: ${DateFormat('h:mm a').format(_startTime)}',
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(context, true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: ListTile(
                          title: Text(
                            'End: ${DateFormat('h:mm a').format(_endTime)}',
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(context, false),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_showHourlyRate)
                  TextFormField(
                    controller: _hourlyRateController,
                    decoration: const InputDecoration(
                      labelText: 'Hourly Rate (£)',
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
                const SizedBox(height: 16),
                if (_showPerDeliveryRate)
                  TextFormField(
                    controller: _perDeliveryRateController,
                    decoration: const InputDecoration(
                      labelText: 'Per Delivery Rate (£)',
                    ),
                    keyboardType: TextInputType.number,
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
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkSubscriptionAndProceed,
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('PUBLISH JOB'),
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
