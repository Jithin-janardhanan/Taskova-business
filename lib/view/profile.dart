import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/Model/colors.dart';
import 'package:taskova_shopkeeper/auth/logout.dart';
import 'package:taskova_shopkeeper/view/business_detial_filling.dart'
    show BusinessFormPage;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String _name = 'User';
  String _email = '';
  String _phoneNumber = '';
  String? _accessToken;
  String? _errorMessage;
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();

  // Business information
  List<Map<String, dynamic>> _businesses = [];
  Map<String, dynamic>? _selectedBusiness;

  // Additional user info
  final String _joinDate = 'April 2025';
  final int _tasksCompleted = 0;
  final bool _emailVerified = false;
  String? _profilePicture;

  // Base URL for images
  final String _baseImageUrl = dotenv.env['BASE_URL'] ?? '';


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');

      if (_accessToken == null) {
        // If no token found, just load data from sharedPreferences
        _name = prefs.getString('user_name') ?? 'User';
        _email = prefs.getString('user_email') ?? '';
        _phoneNumber = prefs.getString('user_phone') ?? '';

        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Try to fetch user data from API using the new endpoint
      try {
        final response = await http
            .get(
              Uri.parse(
                ApiConfig.shopkeeperProfileUrl,
              ),
              headers: {
                'Authorization': 'Bearer $_accessToken',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Parse personal profile data
          final personalProfile = data['personal_profile'];

          setState(() {
            _name =
                personalProfile['name'] ??
                prefs.getString('user_name') ??
                'User';
            _email =
                personalProfile['email'] ?? prefs.getString('user_email') ?? '';
            _phoneNumber = personalProfile['phone_number'] ?? '';
            _profilePicture = personalProfile['profile_picture'];
            _nameController.text = _name;

            // Parse business information
            if (data['businesses'] != null && data['businesses'] is List) {
              _businesses = List<Map<String, dynamic>>.from(data['businesses']);
              if (_businesses.isNotEmpty) {
                _selectedBusiness = _businesses[0];
              }
            }

            _isLoading = false;
          });

          // Update stored values
          await prefs.setString('user_name', _name);
          await prefs.setString('user_email', _email);
          await prefs.setString('user_phone', _phoneNumber);
        } else if (response.statusCode == 401) {
          // Token expired, try to refresh
          final success = await _refreshToken();
          if (success) {
            _loadUserData(); // Retry with new token
          } else {
            _loadFallbackData(prefs);
          }
        } else {
          _loadFallbackData(prefs);
        }
      } catch (e) {
        _loadFallbackData(prefs);
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      _loadFallbackData(prefs);
    }
  }

  void _loadFallbackData(SharedPreferences prefs) {
    setState(() {
      // Fall back to stored data
      _name = prefs.getString('user_name') ?? 'User';
      _email = prefs.getString('user_email') ?? '';
      _phoneNumber = prefs.getString('user_phone') ?? '';
      _nameController.text = _name;
      _isLoading = false;
      _errorMessage = 'Could not update profile from server. Using saved data.';
    });
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        return false;
      }

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
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    try {
      setState(() => _isLoading = true);

      // First try to update on server if we have token
      if (_accessToken != null) {
        try {
          final response = await http
              .patch(
                Uri.parse(
                  'https://anjalitechfifo.pythonanywhere.com/api/shopkeeper/profile/update/',
                ),
                headers: {
                  'Authorization': 'Bearer $_accessToken',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'name': _nameController.text}),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            _name = data['name'] ?? _nameController.text;
          } else if (response.statusCode == 401) {
            // Try to refresh token and update again
            final refreshed = await _refreshToken();
            if (refreshed) {
              await _updateProfile();
              return;
            }
          }
        } catch (e) {
          // If API update fails, just continue with local update
          print("API update failed: $e");
        }
      }

      // Always update locally regardless of API result
      _name = _nameController.text;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _name);

      setState(() {
        _isEditingName = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.secondaryBlue,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Here we would upload the image to the server
        if (_accessToken != null) {
          try {
            // Create a multipart request
            final request = http.MultipartRequest(
              'PATCH',
              Uri.parse(
                'https://anjalitechfifo.pythonanywhere.com/api/shopkeeper/profile/update/',
              ),
            );

            // Add headers
            request.headers.addAll({'Authorization': 'Bearer $_accessToken'});

            // Add the file
            request.files.add(
              await http.MultipartFile.fromPath(
                'profile_picture',
                pickedFile.path,
              ),
            );

            // Send the request
            final response = await request.send().timeout(
              const Duration(seconds: 15),
            );

            if (response.statusCode == 200) {
              // If successful, update the profile picture locally
              final responseData = await http.Response.fromStream(response);
              final data = jsonDecode(responseData.body);

              setState(() {
                _profilePicture = data['profile_picture'];
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile picture updated successfully!'),
                  backgroundColor: AppColors.secondaryBlue,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Failed to upload profile picture. Please try again.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading image: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You need to be logged in to update your profile picture.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not access gallery'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.secondaryBlue),
            onPressed: () {
              LogoutService().logout(context);
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        _buildProfileStats(),
                        const SizedBox(height: 24),
                        _buildAccountDetails(),
                        const SizedBox(height: 24),
                        if (_businesses.isNotEmpty) ...[
                          _buildBusinessDetails(),
                          const SizedBox(height: 24),
                        ],
                        _buildSettingsSection(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.lightBlue,
                backgroundImage:
                    _profilePicture != null
                        ? CachedNetworkImageProvider(
                          '$_baseImageUrl$_profilePicture',
                        )
                        : null,
                child:
                    _profilePicture == null
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
                child: InkWell(
                  onTap: _pickImage,
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
            ],
          ),
          const SizedBox(height: 16),

          // Name (editable)
          if (_isEditingName)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _updateProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _isEditingName = false;
                      _nameController.text = _name;
                    });
                  },
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    setState(() {
                      _isEditingName = true;
                      _nameController.text = _name;
                    });
                  },
                ),
              ],
            ),
          Text(_email, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16, color: AppColors.secondaryBlue),
                SizedBox(width: 4),
                Text(
                  'SHOPKEEPER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.calendar_today, _joinDate, 'Joined'),
          const VerticalDivider(thickness: 1),
          _buildStatItem(Icons.task_alt, '$_tasksCompleted', 'Tasks'),
          const VerticalDivider(thickness: 1),
          _buildStatItem(Icons.business, '${_businesses.length}', 'Businesses'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondaryBlue, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAccountDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailItem(Icons.email, 'Email Address', _email),
          const Divider(),
          _buildDetailItem(Icons.phone, 'Phone Number', _phoneNumber),
          const Divider(),
          _buildDetailItem(Icons.badge, 'Role', 'SHOPKEEPER'),
          const Divider(),
          _buildDetailItem(
            Icons.verified_user,
            'Email Verification',
            _emailVerified ? 'Verified' : 'Not Verified',
            trailing:
                _emailVerified
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification email sent!'),
                          ),
                        );
                      },
                      child: const Text('Verify Now'),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetails() {
    if (_selectedBusiness == null) return const SizedBox();

    final String? businessImage = _selectedBusiness!['image'];

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Business Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              if (_businesses.length > 1)
                TextButton(
                  onPressed: () {
                    // Show business selector dialog
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Select Business'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _businesses.length,
                                itemBuilder: (context, index) {
                                  final business = _businesses[index];
                                  return ListTile(
                                    title: Text(
                                      business['name'] ?? 'Unnamed Business',
                                    ),
                                    subtitle: Text(
                                      business['address'] ?? 'No address',
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedBusiness = business;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                    );
                  },
                  child: const Text('Change'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Business Image
          if (businessImage != null)
            Center(
              child: Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage('$_baseImageUrl$businessImage'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          _buildDetailItem(
            Icons.business,
            'Business Name',
            _selectedBusiness!['name'] ?? 'Unnamed Business',
          ),
          const Divider(),
          _buildDetailItem(
            Icons.location_on,
            'Address',
            _selectedBusiness!['address'] ?? 'No address',
          ),
          const Divider(),
          _buildDetailItem(
            Icons.email,
            'Business Email',
            _selectedBusiness!['email'] ?? 'No email',
          ),
          const Divider(),
          _buildDetailItem(
            Icons.phone,
            'Business Phone',
            _selectedBusiness!['contact_number'] ?? 'No phone',
          ),
          if (_selectedBusiness!['postcode'] != null) ...[
            const Divider(),
            _buildDetailItem(
              Icons.local_post_office,
              'Postcode',
              _selectedBusiness!['postcode'],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.secondaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            Icons.lock_outline,
            'Change Password',
            'Update your account password',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change password feature coming soon'),
                ),
              );
            },
          ),
          _buildSettingItem(
            Icons.business,
            'Manage Business',
            'Edit your business information',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => BusinessFormPage()),
              );
            },
          ),
          _buildSettingItem(
            Icons.notifications_outlined,
            'Notifications',
            'Manage your notification preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings coming soon'),
                ),
              );
            },
          ),
          _buildSettingItem(
            Icons.language,
            'Language',
            'Change your preferred language',
            onTap: () {
              Navigator.of(context).pushNamed('/language');
            },
          ),
          _buildSettingItem(
            Icons.help_outline,
            'Help & Support',
            'Get help or contact support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support center coming soon')),
              );
            },
          ),
          _buildSettingItem(
            Icons.logout,
            'Logout',
            'Sign out from your account',
            textColor: Colors.red,
            onTap: () => LogoutService().logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: textColor ?? AppColors.secondaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textColor ?? AppColors.secondaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
