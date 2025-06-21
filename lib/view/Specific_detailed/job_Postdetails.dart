import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/view/Specific_detailed/applied_job.dart';
import 'package:taskova_shopkeeper/view/Specific_detailed/requesting_driver.dart';
import 'package:taskova_shopkeeper/view/chat.dart';

class JobPostDetailsPage extends StatefulWidget {
  final int jobId;

  const JobPostDetailsPage({super.key, required this.jobId});

  @override
  State<JobPostDetailsPage> createState() => _JobPostDetailsPageState();
}

class _JobPostDetailsPageState extends State<JobPostDetailsPage>
    with SingleTickerProviderStateMixin {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? jobData;
  String? _authToken;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTokenAndFetchJobDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          jobData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load job details. Status code: ${response.statusCode}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Post Details'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : jobData == null
                  ? Center(child: Text("Failed to load data"))
                  : Column(
                      children: [
                        // Job Details Section (Always visible at top)
                        Container(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Job Info Card
                              Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jobData!['title'],
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Text(jobData!['description']),
                                      SizedBox(height: 12),
                                      Text('Hourly Rate: \$${jobData!['hourly_rate']}/hr'),
                                      Text('Per Delivery: \$${jobData!['per_delivery_rate']}/del'),
                                      Text('Time: ${jobData!['start_time']} - ${jobData!['end_time']}'),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),

                              // Business Card
                              Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Business: ${jobData!['business_detail']?['name'] ?? 'Unknown Business'}',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text('Address: ${jobData!['business_detail']?['address'] ?? 'Address not available'}'),
                                      if (jobData!['complimentary_benefits'] != null &&
                                          (jobData!['complimentary_benefits'] as List).isNotEmpty) ...[
                                        SizedBox(height: 8),
                                        Text('Benefits: ${(jobData!['complimentary_benefits'] as List).join(', ')}'),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tab Section
                        Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Theme.of(context).primaryColor,
                            tabs: [
                              Tab(
                                icon: Icon(Icons.work),
                                text: 'Applied Jobs',
                              ),
                              Tab(
                                icon: Icon(Icons.people),
                                text: 'Driver List',
                              ),
                            ],
                          ),
                        ),

                        // Tab Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Applied Jobs Tab
                              AppliedJobsTab(
                                jobId: widget.jobId,
                                authToken: _authToken!,
                                baseUrl: baseUrl,
                                businessLatitude: jobData!['business_detail']?['latitude']?.toDouble(),
                                businessLongitude: jobData!['business_detail']?['longitude']?.toDouble(),
                              ),
                              // Driver List Tab
                              DriverListPage(
                                jobId: widget.jobId,
                                authToken: _authToken!,
                                businessID: jobData!['business_detail']?['id']?.toint(),
                                businessLatitude: jobData!['business_detail']?['latitude']?.toDouble(),
                                businessLongitude: jobData!['business_detail']?['longitude']?.toDouble(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}