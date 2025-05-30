import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EditJobPage extends StatefulWidget {
  final int jobId;
  final String authToken;

  const EditJobPage({super.key, required this.jobId, required this.authToken});

  @override
  _EditJobPageState createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> {
  final _formKey = GlobalKey<FormState>();
  final baseUrl = dotenv.env['BASE_URL'];

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _perDeliveryRateController = TextEditingController();
  final _benefitController = TextEditingController();

  // Job data
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _jobDate;
  bool _isActive = true;
  List<String> _benefits = [];
  int? _businessId;

  // UI State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _perDeliveryRateController.dispose();
    _benefitController.dispose();
    super.dispose();
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Authorization': 'Bearer ${widget.authToken}',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _fetchJobDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/job-posts/${widget.jobId}/'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final jobData = json.decode(response.body);
        _populateFormFields(jobData);
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch job details: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching job details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormFields(Map<String, dynamic> jobData) {
    setState(() {
      _titleController.text = jobData['title'] ?? '';
      _descriptionController.text = jobData['description'] ?? '';
      _hourlyRateController.text = jobData['hourly_rate']?.toString() ?? '';
      _perDeliveryRateController.text =
          jobData['per_delivery_rate']?.toString() ?? '';
      _isActive = jobData['is_active'] ?? true;
      _businessId = jobData['business'];

      // Parse job date
      if (jobData['job_date'] != null) {
        try {
          _jobDate = DateTime.parse(jobData['job_date']);
        } catch (e) {
          _jobDate = null;
        }
      }

      // Parse start time
      if (jobData['start_time'] != null) {
        try {
          final parts = jobData['start_time'].split(':');
          _startTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (e) {
          _startTime = null;
        }
      }

      // Parse end time
      if (jobData['end_time'] != null) {
        try {
          final parts = jobData['end_time'].split(':');
          _endTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (e) {
          _endTime = null;
        }
      }

      // Parse benefits
      if (jobData['complimentary_benefits'] != null) {
        _benefits = List<String>.from(jobData['complimentary_benefits']);
      }
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStartTime
              ? (_startTime ?? TimeOfDay.now())
              : (_endTime ?? TimeOfDay.now()),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _jobDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _jobDate = picked;
      });
    }
  }

  void _addBenefit() {
    if (_benefitController.text.trim().isNotEmpty) {
      setState(() {
        _benefits.add(_benefitController.text.trim());
        _benefitController.clear();
      });
    }
  }

  void _removeBenefit(int index) {
    setState(() {
      _benefits.removeAt(index);
    });
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      var body = json.encode({
        "id": widget.jobId,
        "title": _titleController.text,
        "description": _descriptionController.text,
        "job_date": _jobDate?.toIso8601String().split('T')[0],
        "start_time": _formatTime(_startTime),
        "end_time": _formatTime(_endTime),
        "hourly_rate": _hourlyRateController.text,
        "per_delivery_rate": _perDeliveryRateController.text,
        "complimentary_benefits": _benefits,
        "is_active": _isActive,
        "business": _businessId,
      });

      var response = await http.put(
        Uri.parse('$baseUrl/api/job-posts/edit/${widget.jobId}/'),
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.reasonPhrase}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Job Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveJob,
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
                onPressed: _fetchJobDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildJobDetailsCard(),
          const SizedBox(height: 16),
          _buildScheduleCard(),
          const SizedBox(height: 16),
          _buildPaymentCard(),
          const SizedBox(height: 16),
          _buildBenefitsCard(),
          const SizedBox(height: 16),
          _buildStatusCard(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildJobDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Job Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      value?.trim().isEmpty == true
                          ? 'Job title is required'
                          : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Job Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      value?.trim().isEmpty == true
                          ? 'Job description is required'
                          : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Job Date (Optional)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _jobDate != null
                      ? DateFormat('MMM d, yyyy').format(_jobDate!)
                      : 'Select job date',
                  style: TextStyle(
                    color: _jobDate != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _startTime != null
                            ? _startTime!.format(context)
                            : 'Select start time',
                        style: TextStyle(
                          color:
                              _startTime != null
                                  ? Colors.black
                                  : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        prefixIcon: Icon(Icons.access_time_filled),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _endTime != null
                            ? _endTime!.format(context)
                            : 'Select end time',
                        style: TextStyle(
                          color:
                              _endTime != null
                                  ? Colors.black
                                  : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hourlyRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Hourly Rate (\$)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Hourly rate is required';
                      }
                      if (double.tryParse(value!) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _perDeliveryRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Per Delivery Rate (\$)',
                      prefixIcon: Icon(Icons.delivery_dining),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Delivery rate is required';
                      }
                      if (double.tryParse(value!) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Benefits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _benefitController,
                    decoration: const InputDecoration(
                      labelText: 'Add Benefit',
                      prefixIcon: Icon(Icons.add_circle_outline),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addBenefit(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addBenefit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            if (_benefits.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _benefits.asMap().entries.map((entry) {
                      int index = entry.key;
                      String benefit = entry.value;
                      return Chip(
                        label: Text(benefit),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeBenefit(index),
                        backgroundColor: Colors.blue[50],
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.toggle_on, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Job Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Job is Active'),
              subtitle: Text(
                _isActive
                    ? 'Job is visible to applicants'
                    : 'Job is hidden from applicants',
              ),
              value: _isActive,
              onChanged: (bool value) {
                setState(() {
                  _isActive = value;
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveJob,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isSaving
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }
}
