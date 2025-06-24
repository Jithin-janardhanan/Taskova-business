import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/view/Specific_detailed/requesting_class.dart';

class DriverListPage extends StatefulWidget {
  final int jobId;
  final String authToken;
  final double? businessLatitude;
  final double? businessLongitude;
  final int? businessID;
  final String? subscription;

  const DriverListPage({
    Key? key,
    required this.jobId,
    required this.authToken,
    this.businessLatitude,
    this.businessLongitude,
    this.businessID,
    required this.subscription,
  }) : super(key: key);

  @override
  State<DriverListPage> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverListPage> {
  String? _authToken;
  bool _isLoading = true;
  String? _errorMessage;
  List<Driver> _drivers = [];
  Set<int> _requestingDrivers = {}; // Track which drivers have pending requests

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchDrivers();

    // Debug: Print widget parameters
    print('Widget parameters:');
    print('Job ID: ${widget.jobId}');
    print('Business ID: ${widget.businessID}');
    print('Business Lat: ${widget.businessLatitude}');
    print('Business Lng: ${widget.businessLongitude}');
  }

  Future<void> _loadTokenAndFetchDrivers() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('access_token');

    // Debug: Print available SharedPreferences keys
    print('Available SharedPreferences keys: ${prefs.getKeys()}');
    print('Auth token: ${_authToken?.substring(0, 20)}...');

    if (_authToken == null) {
      setState(() {
        _errorMessage = "Not logged in.";
        _isLoading = false;
      });
      return;
    }

    try {
      await _fetchDrivers();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching drivers: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _fetchDrivers() async {
    var url = (ApiConfig.fulldriverlist);
    final response = await http.get(Uri.parse(url), headers: _getAuthHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Driver> fetchedDrivers =
          data.map((json) => Driver.fromJson(json)).toList();

      // Calculate distance if business location is available
      if (widget.businessLatitude != null && widget.businessLongitude != null) {
        for (var driver in fetchedDrivers) {
          driver.distance = Geolocator.distanceBetween(
            widget.businessLatitude!,
            widget.businessLongitude!,
            driver.latitude,
            driver.longitude,
          );
        }

        // Sort drivers by nearest
        fetchedDrivers.sort((a, b) => a.distance!.compareTo(b.distance!));
      }

      setState(() {
        _drivers = fetchedDrivers;
      });
    } else {
      throw Exception('Failed to load drivers: ${response.statusCode}');
    }
  }

  Future<void> _verifyCurrentUser() async {
    try {
      // Try to get current user info to verify the token and user
      final response = await http.get(
        Uri.parse(
          'http://192.168.20.29:8001/api/user/profile/',
        ), // Adjust endpoint as needed
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        print('Current user data: $userData');
      } else {
        print('Failed to get user data: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error verifying user: $e');
    }
  }

  Future<void> _sendJobRequest(int driverId) async {
    if (widget.businessID == null) {
      _showSnackBar(
        'Business ID is required to send job request',
        isError: true,
      );
      return;
    }

    setState(() {
      _requestingDrivers.add(driverId);
    });

    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      };

      // Debug print to check the values being sent
      print('Sending job request with:');
      print('Job ID: ${widget.jobId}');
      print('Driver ID: $driverId');
      print('Business ID: ${widget.businessID}');
      print(
        'Auth Token: ${_authToken?.substring(0, 20)}...',
      ); // Only show first 20 chars for security

      var request = http.Request(
        'POST',
        Uri.parse('http://192.168.20.29:8001/api/job-application/request/'),
      );

      request.body = json.encode({
        "job_id": widget.jobId,
        "driver_id": driverId,
        "business_id": widget.businessID,
      });

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        print('Job request successful: $responseBody');
        _showSnackBar('Job request sent successfully!');
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Job request failed: ${response.statusCode} - $errorBody');
        print('Request body was: ${request.body}');
        _showSnackBar(
          'Failed to send job request: ${response.statusCode} - $errorBody',
          isError: true,
        );
      }
    } catch (e) {
      print('Error sending job request: $e');
      _showSnackBar('Error sending job request: $e', isError: true);
    } finally {
      setState(() {
        _requestingDrivers.remove(driverId);
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showRequestConfirmationDialog(Driver driver) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Send Job Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send job request to:'),
              SizedBox(height: 8),
              Text(driver.name, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(driver.address),
              if (driver.distance != null) ...[
                SizedBox(height: 4),
                Text(
                  'Distance: ${(driver.distance! / 1609.344).toStringAsFixed(2)} miles',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendJobRequest(driver.id);
              },
              child: Text('Send Request'),
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
        title: Text('Available Drivers'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTokenAndFetchDrivers,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
              : _drivers.isEmpty
              ? Center(
                child: Text(
                  'No drivers available',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              )
              : ListView.builder(
                itemCount: _drivers.length,
                itemBuilder: (context, index) {
                  final driver = _drivers[index];
                  final isRequesting = _requestingDrivers.contains(driver.id);

                  return Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          driver.profilePicture ??
                              'https://via.placeholder.com/150',
                        ),
                        onBackgroundImageError: (_, __) {},
                        child:
                            driver.profilePicture == null
                                ? Icon(Icons.person)
                                : null,
                      ),
                      title: Text(
                        driver.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver.address),
                          if (driver.distance != null)
                            Text(
                              'Distance: ${(driver.distance! / 1609.344).toStringAsFixed(2)} miles',
                              style: TextStyle(color: Colors.blue[600]),
                            ),
                          Text(
                            'Experience: ${driver.drivingDuration} yrs',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing:
                          widget.subscription == 'PREMIUM'
                              ? (isRequesting
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : ElevatedButton(
                                    onPressed:
                                        () => _showRequestConfirmationDialog(
                                          driver,
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: Text('Request'),
                                  ))
                              : ElevatedButton(
                                onPressed: null, // disables the button
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text('Premium Required'),
                              ),

                      contentPadding: EdgeInsets.all(16),
                    ),
                  );
                },
              ),
    );
  }
}
