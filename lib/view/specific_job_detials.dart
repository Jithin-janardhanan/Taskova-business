import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JobPostDetailsPage extends StatefulWidget {
  final int jobId;

  const JobPostDetailsPage({Key? key, required this.jobId}) : super(key: key);

  @override
  State<JobPostDetailsPage> createState() => _JobPostDetailsPageState();
}

class _JobPostDetailsPageState extends State<JobPostDetailsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? jobData;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchJobDetails();
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
        Uri.parse(
          'https://anjalitechfifo.pythonanywhere.com/api/job-posts/${widget.jobId}/',
        ),
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
          _errorMessage =
              'Failed to load job details. Status code: ${response.statusCode}';
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
      appBar: AppBar(title: const Text('Job Post Details')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : jobData == null
              ? const Center(child: Text("Failed to load data"))
              : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    if (jobData!['business_image'] != null)
                      Image.network(
                        'https://anjalitechfifo.pythonanywhere.com${jobData!['business_image']}',
                        height: 200,
                        errorBuilder:
                            (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 100),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      "Title: ${jobData!['title']}",
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text("Description: ${jobData!['description']}"),
                    const SizedBox(height: 8),
                    Text("Business Name: ${jobData!['business_name']}"),
                    const SizedBox(height: 8),
                    Text("Hourly Rate: ${jobData!['hourly_rate']}"),
                    const SizedBox(height: 8),
                    Text("Per Delivery Rate: ${jobData!['per_delivery_rate']}"),
                    const SizedBox(height: 8),
                    Text("Start Time: ${jobData!['start_time']}"),
                    const SizedBox(height: 8),
                    Text("End Time: ${jobData!['end_time']}"),
                    const SizedBox(height: 8),

                    const Text(
                      "Complimentary Benefits:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (jobData!['complimentary_benefits'] != null)
                      ...List<Widget>.from(
                        (jobData!['complimentary_benefits'] as List).map(
                          (item) => Text("• $item"),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
