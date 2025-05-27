import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/view/Job_edit.dart';
import 'package:taskova_shopkeeper/view/bottom_nav.dart';
import 'package:taskova_shopkeeper/view/specific_job_detials.dart';

class MyJobpost extends StatefulWidget {
  const MyJobpost({super.key});

  @override
  State<MyJobpost> createState() => _MyJobpostState();
}

class _MyJobpostState extends State<MyJobpost> {
  final baseUrl = dotenv.env['BASE_URL'];
  String? _authToken;
  bool _isLoading = true;
  String? _errorMessage;

  // Business data
  List<dynamic>? _businessesList;
  Map<String, dynamic>? _businessData;

  // Job posts data
  List<dynamic>? _jobPosts;

  // Selected business index
  int _selectedBusinessIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    try {
      await _loadToken();
      if (_authToken != null) {
        await fetchBusinesses();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _authToken = prefs.getString('access_token');
      });

      if (_authToken == null) {
        setState(() {
          _errorMessage = 'Not logged in. Please login first.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load authentication data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  // Fetch businesses list API
  Future<void> fetchBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch businesses list API
      final businessResponse = await http.get(
        Uri.parse(ApiConfig.businesses),
        headers: _getAuthHeaders(),
      );

      if (businessResponse.statusCode == 200) {
        final List<dynamic> businessesList = json.decode(businessResponse.body);

        setState(() {
          _businessesList = businessesList;
        });

        if (businessesList.isEmpty) {
          setState(() {
            _errorMessage = 'No businesses found for this account';
            _isLoading = false;
          });
          return;
        }

        // Use the first business in the list by default
        setState(() {
          _businessData = businessesList[_selectedBusinessIndex];
        });

        // Fetch jobs for the selected business
        if (_businessData != null && _businessData!['id'] != null) {
          await fetchJobsForBusiness(_businessData!['id']);
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch businesses: ${businessResponse.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  //we can get post of specific business
  Future<void> fetchJobsForBusiness(int businessId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _jobPosts = null;
    });

    try {
      final jobResponse = await http.get(
        Uri.parse('$baseUrl/api/job-posts/business/$businessId/'),
        headers: _getAuthHeaders(),
      );

      if (jobResponse.statusCode == 200) {
        final jobData = json.decode(jobResponse.body);
        setState(() {
          _jobPosts = jobData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch jobs: ${jobResponse.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching jobs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _selectBusiness(int index) {
    if (index >= 0 && index < (_businessesList?.length ?? 0)) {
      setState(() {
        _selectedBusinessIndex = index;
        _businessData = _businessesList![index];
      });

      if (_businessData != null && _businessData!['id'] != null) {
        fetchJobsForBusiness(_businessData!['id']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomePageWithBottomNav()),
            );
          },
        ),
        title: const Text(
          'Job Post',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTokenAndFetchData,
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadTokenAndFetchData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTokenAndFetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildBusinessSection(),
            const SizedBox(height: 24),
            _buildJobsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Job Postings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (_businessData != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Job'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                ),
                onPressed: () {
                  // TODO: Navigate to job creation page
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildJobsList(),
      ],
    );
  }

  Widget _buildJobsList() {
    if (_jobPosts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_jobPosts!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.work_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No Job Postings Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first job posting to attract applicants',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Job Posting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  // TODO: Navigate to job creation page
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _jobPosts!.length,
      itemBuilder: (context, index) => _buildJobCard(_jobPosts![index]),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final String jobTitle = job['title'] ?? 'Untitled Position';
    final String jobType = job['description'] ?? 'Not specified';
    final String location = _businessData!['address'] ?? 'No address provided';
    //  "job_date": DateFormat('yyyy-MM-dd').format(_postDate),

    // Format creation date
    String postedDate = 'Unknown date';
    if (job['created_at'] != null) {
      try {
        final DateTime dateTime = DateTime.parse(job['created_at']);
        final now = DateTime.now();
        final difference = now.difference(dateTime);

        if (difference.inDays == 0) {
          postedDate = 'Today';
        } else if (difference.inDays == 1) {
          postedDate = 'Yesterday';
        } else if (difference.inDays < 7) {
          postedDate = '${difference.inDays} days ago';
        } else {
          postedDate = DateFormat('MMM d, yyyy').format(dateTime);
        }
      } catch (e) {
        postedDate = 'Invalid date';
      }
    }
    String jobDateFormatted = 'Not set';
    if (job['job_date'] != null) {
      try {
        final jobDate = DateTime.parse(job['job_date']);
        jobDateFormatted = DateFormat('MMM d, yyyy').format(jobDate);
      } catch (e) {
        jobDateFormatted = 'Invalid date';
      }
    }

    Color statusColor = Colors.green;
    String statusText = 'Active';

    if (job['status'] != null) {
      switch (job['is'].toString().toLowerCase()) {
        case 'active':
          statusColor = Colors.green;
          statusText = 'Active';
          break;
        case 'closed':
          statusColor = Colors.red;
          statusText = 'Closed';
          break;
        case 'draft':
          statusColor = Colors.orange;
          statusText = 'Draft';
          break;
        case 'pending':
          statusColor = Colors.blue;
          statusText = 'Pending';
          break;
        default:
          statusColor = Colors.grey;
          statusText = job['status'].toString();
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status indicator
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Job ID: #${job['id'] ?? 'N/A'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Job details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            children: [
                              _buildJobTag(Icons.location_on, location),
                              _buildJobTag(Icons.work, jobType),
                              _buildJobTag(
                                Icons.calendar_today,
                                'Posted: $postedDate',
                              ),
                              _buildJobTag(
                                Icons.event,
                                'Job Date: $jobDateFormatted',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            job['applicants_count'] != null
                                ? '${job['applicants_count']} Applicants'
                                : '0 Applicants',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ],
                ),

                // Actions
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => EditJobPage(
                                    jobId: job['id'],
                                    authToken: _authToken!,
                                  ),
                            ),
                          );

                          // If job was updated successfully, refresh the job list
                          if (result == true) {
                            if (_businessData != null &&
                                _businessData!['id'] != null) {
                              await fetchJobsForBusiness(_businessData!['id']);
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.people, size: 16),
                        label: const Text(
                          'View Applications',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      JobPostDetailsPage(jobId: job['id']),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTag(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
