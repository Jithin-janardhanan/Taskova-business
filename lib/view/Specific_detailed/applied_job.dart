import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taskova_shopkeeper/view/chat.dart';

class AppliedJobsTab extends StatefulWidget {
  final int jobId;
  final String authToken;
  final String baseUrl;
  final double? businessLatitude;
  final double? businessLongitude;

  const AppliedJobsTab({
    super.key,
    required this.jobId,
    required this.authToken,
    required this.baseUrl,
    this.businessLatitude,
    this.businessLongitude,
  });

  @override
  State<AppliedJobsTab> createState() => _AppliedJobsTabState();
}

class _AppliedJobsTabState extends State<AppliedJobsTab> {
  bool _isLoading = true;
  List<dynamic> jobRequests = [];
  List<dynamic> filteredJobRequests = [];

  // Filter variables
  String _selectedFilter = 'All';
  double _maxDistance = 50.0;
  double _minRating = 0.0;
  bool _isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    fetchJobRequests();
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Authorization': 'Bearer ${widget.authToken}',
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchJobRequests() async {
    try {
      var request = http.Request(
        'GET',
        Uri.parse('${widget.baseUrl}/api/job-requests/list/${widget.jobId}'),
      );
      request.headers.addAll({'Authorization': 'Bearer ${widget.authToken}'});

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        final List<dynamic> requestData = json.decode(responseBody);
        setState(() {
          jobRequests = requestData;
          _applyFilters();
        });
      } else {
        print("Job Requests Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Job Requests Exception: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 3959;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  double? _getDriverDistance(Map<String, dynamic> request) {
    if (widget.businessLatitude == null ||
        widget.businessLongitude == null ||
        request['latitude'] == null ||
        request['longitude'] == null) {
      return null;
    }
    return _calculateDistance(
      widget.businessLatitude!,
      widget.businessLongitude!,
      request['latitude'].toDouble(),
      request['longitude'].toDouble(),
    );
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(jobRequests);

    if (_selectedFilter == 'Accepted') {
      filtered = filtered.where((req) => req['status'] == 'accepted').toList();
    } else if (_selectedFilter == 'Pending') {
      filtered = filtered.where((req) => req['status'] == 'pending').toList();
    }

    filtered = filtered.where((req) {
      double? distance = _getDriverDistance(req);
      return distance == null || distance <= _maxDistance;
    }).toList();

    filtered = filtered.where((req) {
      double rating = (req['average_rating'] ?? 0.0).toDouble();
      return rating >= _minRating;
    }).toList();

    filtered.sort((a, b) {
      double? distanceA = _getDriverDistance(a);
      double? distanceB = _getDriverDistance(b);
      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;
      return distanceA.compareTo(distanceB);
    });

    setState(() {
      filteredJobRequests = filtered;
    });
  }

  Future<void> _hireDriver(int jobRequestId) async {
    final url = Uri.parse('${widget.baseUrl}/api/job-requests/$jobRequestId/accept/');
    try {
      final response = await http.post(
        url,
        headers: _getAuthHeaders(),
        body: json.encode({}),
      );
      if (response.statusCode == 200) {
        await fetchJobRequests();
      }
    } catch (e) {
      print('Hire Error: $e');
    }
  }

  Future<void> _cancelJobRequest(int jobRequestId) async {
    final url = Uri.parse('${widget.baseUrl}/api/job-request/$jobRequestId/cancel-by-shopkeeper/');
    try {
      final response = await http.post(
        url,
        headers: _getAuthHeaders(),
        body: json.encode({}),
      );
      if (response.statusCode == 200) {
        await fetchJobRequests();
      } else {
        print('Cancel Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Cancel Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isFilterVisible = !_isFilterVisible;
          });
        },
        child: Icon(_isFilterVisible ? Icons.filter_alt_off : Icons.filter_alt),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Section
                  if (_isFilterVisible)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Text('Status: '),
                                DropdownButton<String>(
                                  value: _selectedFilter,
                                  items: ['All', 'Accepted', 'Pending'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedFilter = newValue!;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text('Max Distance: ${_maxDistance.toInt()} miles'),
                            Slider(
                              value: _maxDistance,
                              min: 1,
                              max: 100,
                              divisions: 99,
                              onChanged: (double value) {
                                setState(() {
                                  _maxDistance = value;
                                  _applyFilters();
                                });
                              },
                            ),
                            Text('Min Rating: ${_minRating.toStringAsFixed(1)}'),
                            Slider(
                              value: _minRating,
                              min: 0,
                              max: 5,
                              divisions: 50,
                              onChanged: (double value) {
                                setState(() {
                                  _minRating = value;
                                  _applyFilters();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Applied Drivers Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Applied Drivers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('${filteredJobRequests.length}/${jobRequests.length}'),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Drivers List
                  if (filteredJobRequests.isEmpty)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No drivers match your criteria'),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredJobRequests.map((req) {
                      final bool isAccepted = req['status'] == 'accepted';
                      final bool isCancelled = req['status'] == 'cancelled_by_shopkeeper' ||
                          req['status'] == 'cancelled_by_driver';
                      final int jobRequestId = req['job_request_id'];
                      final int driverId = req['driver_id'];
                      final String driverName = req['driver_name'] ?? 'Unknown Driver';
                      final double averageRating = (req['average_rating'] ?? 0.0).toDouble();
                      final String preferredAddress = req['preferred_working_address'] ?? 'Address not provided';
                      final double? distance = _getDriverDistance(req);

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driverName,
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        Text('ID: $driverId'),
                                      ],
                                    ),
                                  ),
                                  if (isAccepted)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'HIRED',
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    )
                                  else if (isCancelled)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        req['status'] == 'cancelled_by_shopkeeper'
                                            ? 'CANCELLED BY YOU'
                                            : 'CANCELLED BY DRIVER',
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text('Rating: ${averageRating > 0 ? averageRating.toStringAsFixed(1) : 'No rating'}'),
                              if (distance != null) Text('Distance: ${distance.toStringAsFixed(1)} mi'),
                              Text('Address: $preferredAddress', maxLines: 2, overflow: TextOverflow.ellipsis),
                              SizedBox(height: 12),
                              if (isAccepted)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(jobRequestId: jobRequestId),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.chat),
                                    label: Text('Chat'),
                                  ),
                                )
                              else if (!isCancelled)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await _hireDriver(jobRequestId);
                                        },
                                        icon: Icon(Icons.work),
                                        label: Text('Hire Driver'),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await _cancelJobRequest(jobRequestId);
                                        },
                                        icon: Icon(Icons.cancel),
                                        label: Text('Cancel'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }
}