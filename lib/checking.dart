import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BusinessJobsPage extends StatefulWidget {
  const BusinessJobsPage({Key? key}) : super(key: key);

  @override
  State<BusinessJobsPage> createState() => _BusinessJobsPageState();
}

class _BusinessJobsPageState extends State<BusinessJobsPage> {
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

  Future<void> fetchBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch businesses list
      final businessResponse = await http.get(
        Uri.parse('https://anjalitechfifo.pythonanywhere.com/api/shopkeeper/businesses/'),
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
          _errorMessage = 'Failed to fetch businesses: ${businessResponse.statusCode}';
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

  Future<void> fetchJobsForBusiness(int businessId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _jobPosts = null;
    });

    try {
      final jobResponse = await http.get(
        Uri.parse('https://anjalitechfifo.pythonanywhere.com/api/job-posts/business/$businessId/'),
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
        title: const Text(
          'Business & Jobs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          // Business selector dropdown if multiple businesses exist
          if (_businessesList != null && _businessesList!.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: DropdownButton<int>(
                underline: Container(),
                icon: const Icon(Icons.business, color: Colors.white),
                dropdownColor: Colors.blue[700],
                hint: const Text('Select Business', style: TextStyle(color: Colors.white)),
                value: _selectedBusinessIndex,
                items: List.generate(_businessesList!.length, (index) {
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      _businessesList![index]['name'] ?? 'Business ${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }),
                onChanged: (selectedIndex) {
                  if (selectedIndex != null) {
                    _selectBusiness(selectedIndex);
                  }
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTokenAndFetchData,
          ),
        ],
      ),
      floatingActionButton: !_isLoading && _errorMessage == null && _businessData != null 
        ? FloatingActionButton(
            onPressed: () {
              // TODO: Navigate to job creation page
            },
            backgroundColor: Colors.blue[700],
            child: const Icon(Icons.add),
          )
        : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            _buildBusinessSection(),
            const SizedBox(height: 24),
            _buildJobsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Business Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (_businessData != null)
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                onPressed: () {
                  // TODO: Navigate to edit business page
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBusinessCard(),
      ],
    );
  }

  Widget _buildBusinessCard() {
    if (_businessData == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.business, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No business profile available',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a business profile to post jobs',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_business),
                label: const Text('Create Business Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  // TODO: Navigate to create business page
                },
              ),
            ],
          ),
        ),
      );
    }

    final bool hasLogo = _businessData!['logo'] != null && _businessData!['logo'].toString().isNotEmpty;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Logo or Placeholder
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: hasLogo ? null : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: hasLogo ? DecorationImage(
                      image: NetworkImage(_businessData!['logo']),
                      fit: BoxFit.cover,
                    ) : null,
                  ),
                  child: !hasLogo ? Icon(Icons.business, size: 36, color: Colors.grey[500]) : null,
                ),
                const SizedBox(width: 16),
                // Business Name and Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _businessData!['name'] ?? 'Unnamed Business',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_businessData!['industry'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            _businessData!['industry'],
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildBusinessInfoRow(Icons.location_on, _businessData!['address'] ?? 'No address provided'),
            _buildBusinessInfoRow(Icons.phone, _businessData!['phone'] ?? 'No phone provided'),
            _buildBusinessInfoRow(Icons.email, _businessData!['email'] ?? 'No email provided'),
            if (_businessData!['website'] != null && _businessData!['website'].toString().isNotEmpty)
              _buildBusinessInfoRow(Icons.link, _businessData!['website']),
            
            if (_businessData!['description'] != null && _businessData!['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _businessData!['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ],
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
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
    if (_businessData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Create a business profile to post jobs'),
        ),
      );
    }

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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    final String jobType = job['job_type'] ?? 'Not specified';
    final String location = job['location'] ?? 'No location';
    
    // Format salary range if available
    String salary = 'Not specified';
    if (job['salary_from'] != null && job['salary_to'] != null) {
      final salaryFormat = NumberFormat('#,###');
      salary = '₹${salaryFormat.format(job['salary_from'])} - ₹${salaryFormat.format(job['salary_to'])}';
    }
    
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

    Color statusColor = Colors.green;
    String statusText = 'Active';

    if (job['status'] != null) {
      switch(job['status'].toString().toLowerCase()) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                              _buildJobTag(Icons.calendar_today, 'Posted: $postedDate'),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        Text(
                          salary,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Skills
                if (job['skills'] != null && job['skills'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Skills Required:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (job['skills'] as String)
                        .split(',')
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                skill.trim(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                
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
                        onPressed: () {
                          // TODO: Navigate to edit job page
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.people, size: 16),
                        label: const Text('View Applications'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          // TODO: Navigate to applications page
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
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}