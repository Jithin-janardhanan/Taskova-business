import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/view/Specific_detailed/requesting_class.dart';
//import 'package:taskova_shopkeeper/view/driverspage.dart' hide Driver;

class DriverListPage extends StatefulWidget {
  final int jobId;
  final String authToken;
  final double? businessLatitude;
  final double? businessLongitude;
  final int? businessID;

  const DriverListPage({
    Key? key,
    required this.jobId,
    required this.authToken,
    this.businessLatitude,
    this.businessLongitude,
    this.businessID
  }) : super(key: key);

  @override
  State<DriverListPage> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverListPage> {
  String? _authToken;
  bool _isLoading = true;
  String? _errorMessage;
  List<Driver> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchDrivers();
  }

  Future<void> _loadTokenAndFetchDrivers() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('access_token');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                itemCount: _drivers.length,
                itemBuilder: (context, index) {
                  final driver = _drivers[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          driver.profilePicture ??
                              'https://via.placeholder.com/150',
                        ),
                      ),

                      title: Text(driver.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver.address),
                          if (driver.distance != null)
                            Text(
                              'Distance: ${(driver.distance! / 1609.344).toStringAsFixed(2)} miles',
                            ),
                        ],
                      ),

                      trailing: Text('${driver.drivingDuration} yrs'),
                    ),
                  );
                },
              ),
    );
  }
}
