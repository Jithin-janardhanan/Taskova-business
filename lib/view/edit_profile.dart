import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/Model/colors.dart';

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ProfileEditPage({super.key, this.initialData});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _accessToken;
  File? _selectedImage;
  String? _currentProfilePicture;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Base URL for images
  final String _baseImageUrl = dotenv.env['BASE_URL'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
    _initializeData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
  }

  void _initializeData() {
    if (widget.initialData != null) {
      final personalProfile = widget.initialData!['personal_profile'] ?? {};
      _nameController.text = personalProfile['name'] ?? '';
      _emailController.text = personalProfile['email'] ?? '';
      _phoneController.text = personalProfile['phone_number'] ?? '';
      _currentProfilePicture = personalProfile['profile_picture'];
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Could not access gallery: ${e.toString()}');
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
      _currentProfilePicture = null;
    });
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        await prefs.setString('access_token', _accessToken!);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_accessToken == null) {
      _showErrorSnackBar('You need to be logged in to update your profile');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create multipart request to handle both form data and file upload
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/profile/'),
      );

      // Add headers
      request.headers.addAll({'Authorization': 'Bearer $_accessToken'});

      // Add form fields with nested structure
      request.fields.addAll({
        'personal_profile[name]': _nameController.text.trim(),
        'personal_profile[email]': _emailController.text.trim(),
        'personal_profile[phone_number]': _phoneController.text.trim(),
      });

      // Add profile picture if selected
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'personal_profile[profile_picture]',
            _selectedImage!.path,
          ),
        );
      }

      // Send the request
      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);

        // Update local storage
        await _updateLocalStorage(data);

        _showSuccessSnackBar('Profile updated successfully!');

        // Return updated data to previous screen
        Navigator.pop(context, data);
      } else if (response.statusCode == 401) {
        // Try to refresh token and retry
        final refreshed = await _refreshToken();
        if (refreshed) {
          await _updateProfile();
          return;
        } else {
          _showErrorSnackBar('Session expired. Please login again.');
        }
      } else {
        final responseData = await http.Response.fromStream(response);
        final errorData = jsonDecode(responseData.body);
        _showErrorSnackBar(
          'Failed to update profile: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Network error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocalStorage(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final personalProfile = data['personal_profile'] ?? {};

    await prefs.setString('user_name', personalProfile['name'] ?? '');
    await prefs.setString('user_email', personalProfile['email'] ?? '');
    await prefs.setString('user_phone', personalProfile['phone_number'] ?? '');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.secondaryBlue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.lightBlue,
              backgroundImage:
                  _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (_currentProfilePicture != null
                          ? CachedNetworkImageProvider(
                            '$_baseImageUrl$_currentProfilePicture',
                          )
                          : null),
              child:
                  (_selectedImage == null && _currentProfilePicture == null)
                      ? const Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.primaryBlue,
                      )
                      : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'camera') {
                      _pickImage();
                    } else if (value == 'remove') {
                      _removeImage();
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'camera',
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt),
                              SizedBox(width: 8),
                              Text('Change Photo'),
                            ],
                          ),
                        ),
                        if (_selectedImage != null ||
                            _currentProfilePicture != null)
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Remove Photo',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to change profile picture',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: AppColors.secondaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.secondaryBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppColors.secondaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Picture Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: _buildProfilePictureSection(),
                      ),

                      const SizedBox(height: 24),

                      // Form Fields
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildFormField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),

                            _buildFormField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'Enter your email address',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null; // Email is optional
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            _buildFormField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: 'Enter your phone number',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                                validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number required';
    }

    final phone = value.replaceAll(RegExp(r'\D'), ''); // Remove all non-digits

    // Valid UK mobile numbers: start with '07' (local) or '447' (international)
    final isValidUK = (phone.startsWith('07') && phone.length == 11) ||
                      (phone.startsWith('447') && phone.length == 12);

    if (!isValidUK) {
      return 'Enter a valid UK mobile number';
    }

    return null;
  },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child:
                              _isLoading
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
                                    'Update Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondaryBlue,
                            side: const BorderSide(
                              color: AppColors.secondaryBlue,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
