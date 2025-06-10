import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/Model/postcode.dart';

class BusinessFetchAndEditPage extends StatefulWidget {
  const BusinessFetchAndEditPage({super.key});

  @override
  State<BusinessFetchAndEditPage> createState() =>
      _BusinessFetchAndEditPageState();
}

class _BusinessFetchAndEditPageState extends State<BusinessFetchAndEditPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _name = TextEditingController();
  TextEditingController _address = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _contact = TextEditingController();
  TextEditingController _postcode = TextEditingController();
  TextEditingController _lat = TextEditingController();
  TextEditingController _lng = TextEditingController();

  String? _token;
  int? _businessId;
  File? _image;
  bool _loading = true;
  String? _error;

  // Blue theme colors
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color backgroundBlue = Color(0xFFF0F7FF);
  static const Color cardBlue = Color(0xFFE6F2FF);

  @override
  void initState() {
    super.initState();
    _loadAndFetchFirstBusiness();
  }

  Future<void> _loadAndFetchFirstBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');

    if (_token == null) {
      setState(() {
        _error = "Access token missing.";
        _loading = false;
      });
      return;
    }

    final res = await http.get(
      Uri.parse(ApiConfig.businesses),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (res.statusCode == 200) {
      List businesses = jsonDecode(res.body);
      if (businesses.isEmpty) {
        setState(() {
          _error = "No business found.";
          _loading = false;
        });
        return;
      }

      final first = businesses.first;
      setState(() {
        _businessId = first['id'];
        _name.text = first['name'] ?? '';
        _address.text = first['address'] ?? '';
        _email.text = first['email'] ?? '';
        _contact.text = first['contact_number'] ?? '';
        _postcode.text = first['postcode'] ?? '';
        _lat.text = first['latitude']?.toString() ?? '';
        _lng.text = first['longitude']?.toString() ?? '';
        _loading = false;
      });
    } else {
      setState(() {
        _error = "Failed to fetch businesses.";
        _loading = false;
      });
    }
  }

  void _onAddressSelected(double latitude, double longitude, String address) {
    setState(() {
      _lat.text = latitude.toString();
      _lng.text = longitude.toString();
      _address.text = address;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Address updated successfully'),
          ],
        ),
        backgroundColor: lightBlue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_businessId == null || !_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/businesses/$_businessId/'),
    );

    request.headers['Authorization'] = 'Bearer $_token';
    request.fields.addAll({
      'name': _name.text,
      'address': _address.text,
      'email': _email.text,
      'contact_number': _contact.text,
      'postcode': _postcode.text,
      'latitude': _lat.text,
      'longitude': _lng.text,
    });

    if (_image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', _image!.path),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.business, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Business updated successfully"),
            ],
          ),
          backgroundColor: lightBlue,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text("Error: $body")),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    setState(() => _loading = false);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool readOnly = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              prefixIcon != null
                  ? Icon(prefixIcon, color: lightBlue, size: 20)
                  : null,
          labelStyle: TextStyle(
            color: primaryBlue,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
          filled: true,
          fillColor: readOnly ? cardBlue : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: accentBlue.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: accentBlue.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: lightBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
        readOnly: readOnly,
        maxLines: maxLines,
        validator: validator,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14,
          color: readOnly ? Colors.grey[700] : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: backgroundBlue,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(lightBlue),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading business details...',
                style: TextStyle(color: primaryBlue, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: backgroundBlue,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Colors.red[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        title: const Text(
          'Edit Business',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Details Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, color: lightBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Business Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _name,
                      label: 'Business Name',
                      prefixIcon: Icons.store,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter business name';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _email,
                      label: 'Email',
                      prefixIcon: Icons.email,
                      readOnly: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      controller: _contact,
                      label: 'Contact Number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter contact number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: lightBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Location Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Postcode Search
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentBlue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search by Postcode',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          PostcodeSearchWidget(
                            onAddressSelected: _onAddressSelected,
                            placeholderText: 'Enter postcode to update address',
                            postcodeController: _postcode,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _address,
                      label: 'Address',
                      hint: 'Updated automatically when postcode is selected',
                      prefixIcon: Icons.home,
                      readOnly: true,
                      maxLines: 2,
                    ),
                    _buildTextField(
                      controller: _postcode,
                      label: 'Postcode',
                      hint: 'Use postcode search above to update',
                      prefixIcon: Icons.local_post_office,
                      readOnly: true,
                    ),

                    // Coordinates Row
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: _buildTextField(
                    //         controller: _lat,
                    //         label: 'Latitude',
                    //         hint: 'Auto-updated',
                    //         prefixIcon: Icons.my_location,
                    //         readOnly: true,
                    //       ),
                    //     ),
                    //     const SizedBox(width: 12),
                    //     Expanded(
                    //       child: _buildTextField(
                    //         controller: _lng,
                    //         label: 'Longitude',
                    //         hint: 'Auto-updated',
                    //         prefixIcon: Icons.place,
                    //         readOnly: true,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Image Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, color: lightBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Business Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_image != null) ...[
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentBlue.withOpacity(0.3),
                          ),
                          image: DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(
                          _image == null
                              ? Icons.add_photo_alternate
                              : Icons.change_circle,
                          size: 18,
                        ),
                        label: Text(
                          _image == null ? 'Add Image' : 'Change Image',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: primaryBlue.withOpacity(0.3),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Update Business',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
