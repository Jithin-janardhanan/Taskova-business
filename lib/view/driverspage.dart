import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



class Driver {
  final String name;
  final String phoneNumber;
  final String address;
  final String? preferredWorkingArea;
  final String preferredWorkingAddress;
  final double latitude;
  final double longitude;
  final String profilePicture;
  final bool isBritishCitizen;
  final bool hasCriminalHistory;
  final bool isBlocked;
  final bool hasDisability;
  final String? disabilityCertificate;
  final String createdAt;
  final String updatedAt;
  final String email;

  Driver({
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.preferredWorkingArea,
    required this.preferredWorkingAddress,
    required this.latitude,
    required this.longitude,
    required this.profilePicture,
    required this.isBritishCitizen,
    required this.hasCriminalHistory,
    required this.isBlocked,
    required this.hasDisability,
    this.disabilityCertificate,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      preferredWorkingArea: json['preferred_working_area'],
      preferredWorkingAddress: json['preferred_working_address'] ?? '',
      latitude: json['latitude'] is num ? json['latitude'].toDouble() : 0.0,
      longitude: json['longitude'] is num ? json['longitude'].toDouble() : 0.0,
      profilePicture: json['profile_picture'] ?? '',
      isBritishCitizen: json['is_british_citizen'] ?? false,
      hasCriminalHistory: json['has_criminal_history'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      hasDisability: json['has_disability'] ?? false,
      disabilityCertificate: json['disability_certificate'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class DriverService {
  static const String baseUrl = 'https://anjalitechfifo.pythonanywhere.com/api';
  static const String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzQ3NDgxOTQ0LCJpYXQiOjE3NDczOTU1NDQsImp0aSI6IjQwYjkzZmI3MzIxMTRlMjZhZmZkNTgxYTY4Y2ZhZTEwIiwidXNlcl9pZCI6MTd9.Cfo7xc1SrwxWRW_pD-Xp7IiTEiuKb1ZUIkIrqGebgk4';

  static Future<List<Driver>> fetchDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Driver.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load drivers: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching drivers: $e');
    }
  }
}

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  late Future<List<Driver>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _driversFuture = DriverService.fetchDrivers();
  }

  void _refreshDrivers() {
    setState(() {
      _driversFuture = DriverService.fetchDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDrivers,
          ),
        ],
      ),
      body: FutureBuilder<List<Driver>>(
        future: _driversFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshDrivers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No drivers found'));
          }

          final drivers = snapshot.data!;
          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return DriverListItem(
                driver: driver,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DriverDetailScreen(driver: driver),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new driver functionality would go here
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add driver feature coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DriverListItem extends StatelessWidget {
  final Driver driver;
  final VoidCallback onTap;

  const DriverListItem({
    super.key,
    required this.driver,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(driver.profilePicture),
          onBackgroundImageError: (_, __) {},
          child: driver.profilePicture.isEmpty
              ? Text(driver.name.isNotEmpty ? driver.name[0] : '?')
              : null,
        ),
        title: Text(driver.name),
        subtitle: Text(driver.phoneNumber),
        trailing: Icon(
          driver.isBlocked ? Icons.block : Icons.check_circle,
          color: driver.isBlocked ? Colors.red : Colors.green,
        ),
        onTap: onTap,
      ),
    );
  }
}

class DriverDetailScreen extends StatelessWidget {
  final Driver driver;

  const DriverDetailScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: driver.email,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(driver.profilePicture),
                  onBackgroundImageError: (_, __) {},
                  child: driver.profilePicture.isEmpty
                      ? Text(
                          driver.name.isNotEmpty ? driver.name[0] : '?',
                          style: const TextStyle(fontSize: 40),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(context, [
              _buildInfoRow('Name', driver.name),
              _buildInfoRow('Email', driver.email),
              _buildInfoRow('Phone', driver.phoneNumber),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(context, [
              _buildInfoRow('Address', driver.address),
              _buildInfoRow('Working Address', driver.preferredWorkingAddress),
              if (driver.preferredWorkingArea != null)
                _buildInfoRow('Working Area', driver.preferredWorkingArea!),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(context, [
              _buildInfoRow(
                'British Citizen',
                driver.isBritishCitizen ? 'Yes' : 'No',
                icon: driver.isBritishCitizen
                    ? Icons.check_circle
                    : Icons.cancel,
                iconColor:
                    driver.isBritishCitizen ? Colors.green : Colors.red,
              ),
              _buildInfoRow(
                'Criminal History',
                driver.hasCriminalHistory ? 'Yes' : 'No',
                icon: driver.hasCriminalHistory
                    ? Icons.warning
                    : Icons.check_circle,
                iconColor:
                    driver.hasCriminalHistory ? Colors.red : Colors.green,
              ),
              _buildInfoRow(
                'Account Status',
                driver.isBlocked ? 'Blocked' : 'Active',
                icon: driver.isBlocked ? Icons.block : Icons.check_circle,
                iconColor: driver.isBlocked ? Colors.red : Colors.green,
              ),
              _buildInfoRow(
                'Disability',
                driver.hasDisability ? 'Yes' : 'No',
                icon: driver.hasDisability
                    ? Icons.accessible
                    : Icons.accessibility_new,
                iconColor:
                    driver.hasDisability ? Colors.blue : Colors.green,
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(context, [
              _buildInfoRow('Created', _formatDate(driver.createdAt)),
              _buildInfoRow('Updated', _formatDate(driver.updatedAt)),
            ]),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Map functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Map feature coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('View on Map'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(value)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}