import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/view/bottom_nav.dart';
import 'package:taskova_shopkeeper/view/Jobpost/instant_job_post.dart';
import 'package:taskova_shopkeeper/view/Jobpost/schedulejob_post.dart';
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
  int applicantsCount = 0;

  // Selected business index
  final int _selectedBusinessIndex = 0;

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

  //Application count
  Future<int> fetchApplicantsCount(int jobId) async {
    try {
      final request = http.Request(
        'GET',
        Uri.parse(
          '$baseUrl/api/job-requests/list/$jobId/',
        ), // already filtered by job
      );
      request.headers.addAll(_getAuthHeaders());

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);

        if (data is List) {
          return data.length;
        } else {
          print('Unexpected format: not a list');
        }
      } else {
        print('Failed to fetch applicant count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }

    return 0;
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

      // Replace the fetchJobsForBusiness method's setState part with this:

      if (jobResponse.statusCode == 200) {
        final jobData = json.decode(jobResponse.body);

        // Parallelize fetching applicant counts
        final futures =
            jobData.map<Future<void>>((job) async {
              final count = await fetchApplicantsCount(job['id']);
              job['applicants_count'] = count;
            }).toList();

        await Future.wait(futures);

        // Sort jobs by created_at date in descending order (latest first)
        jobData.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['created_at'] ?? '');
            final dateB = DateTime.parse(b['created_at'] ?? '');
            return dateB.compareTo(dateA); // Descending order (latest first)
          } catch (e) {
            return 0; // If parsing fails, keep original order
          }
        });

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
        _errorMessage = 'Error fetching jobs: $e';
        _isLoading = false;
      });
    }
  }

  void _showPostJobOptions(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Choose Job Type"),
            content: Text(
              "Do you want to hire for today or schedule for another day?",
            ),
            actions: [
              TextButton.icon(
                icon: Icon(Icons.flash_on),
                label: Text("Hire for Today"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InstatJobPost(),
                    ),
                  );
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.calendar_today),
                label: Text("Hire for Another Day"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleJobPost(),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  // Add this delete method to your _MyJobpostState class:

  Future<void> _deleteJob(int jobId, String jobTitle) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/job-posts/$jobId/manual-delete/'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success - refresh the job list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "$jobTitle" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh jobs list
        if (_businessData != null && _businessData!['id'] != null) {
          await fetchJobsForBusiness(_businessData!['id']);
        }
      } else {
        throw Exception('Failed to delete job: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting job: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this confirmation dialog method:
  void _showDeleteConfirmation(int jobId, String jobTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Job Post'),
          content: Text(
            'Are you sure you want to delete "$jobTitle"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteJob(jobId, jobTitle);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to your desired page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePageWithBottomNav()),
        );
        return false; // prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomePageWithBottomNav(),
                ),
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
      ),
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
                onPressed: () => _showPostJobOptions(context),
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
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Create Job Posting',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => _showPostJobOptions(context),
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

    // Replace the status logic in your _buildJobCard method with this:

    Color statusColor = Colors.green;
    String statusText = 'Active';

    if (job['status'] != null) {
      switch (job['status'].toString().toLowerCase()) {
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
        case 'inactive':
          statusColor = Colors.grey;
          statusText = 'Inactive';
          break;
        default:
          statusColor = Colors.grey;
          statusText = job['status'].toString();
      }
    } else {
      // Fallback to is_active field if status is null
      if (job['is_active'] == true) {
        statusColor = Colors.green;
        statusText = 'Active';
      } else {
        statusColor = Colors.red;
        statusText = 'Inactive';
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
                            runSpacing: 8,
                            children: [
                              _buildJobTag(
                                Icons.location_on,
                                location,
                                iconColor: Colors.blue,
                              ),
                              _buildJobTag(
                                Icons.work,
                                jobType,
                                iconColor: Colors.deepOrange,
                              ),
                              _buildJobTag(
                                Icons.calendar_today,
                                'Posted: $postedDate',
                                iconColor: Colors.green,
                              ),
                              _buildJobTag(
                                Icons.event,
                                'Job Date: $jobDateFormatted',
                                iconColor: Colors.purple,
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
                            '${job['applicants_count'] ?? 0} Applicants',
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
                        icon: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () {
                          _showDeleteConfirmation(job['id'], jobTitle);
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

  Widget _buildJobTag(
    IconData icon,
    String text, {
    Color iconColor = Colors.grey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
