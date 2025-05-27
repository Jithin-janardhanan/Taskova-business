import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/Model/colors.dart';
import 'package:taskova_shopkeeper/auth/registration.dart';
import 'package:taskova_shopkeeper/language/language_provider.dart';
import 'package:taskova_shopkeeper/view/business_detial_filling.dart';

class ProfileDetailFillingPage extends StatefulWidget {
  const ProfileDetailFillingPage({super.key});

  @override
  State<ProfileDetailFillingPage> createState() =>
      _ProfileDetailFillingPageState();
}

class _ProfileDetailFillingPageState extends State<ProfileDetailFillingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _accessToken;
  String? _userName;
  final bool _includeBusinessProfile = false;
  String? _existingProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accessToken = prefs.getString('access_token');
      _userName = prefs.getString('user_name') ?? "";
      _nameController.text = _userName ?? "";

      // Load the profile picture URL if it exists
      String? storedProfilePictureUrl = prefs.getString('user_profile_picture');
      print("Loaded access_token: $_accessToken");
      print("Loaded user_name: $_userName");
      print("Loaded profile picture URL: $storedProfilePictureUrl");

      // If a profile picture URL exists, attempt to display it
      if (storedProfilePictureUrl != null &&
          storedProfilePictureUrl.isNotEmpty) {
        _existingProfileImageUrl = storedProfilePictureUrl;
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final File imageFile = File(image.path);
        if (await imageFile.exists()) {
          print("Image selected: ${image.path}");
          setState(() {
            _profileImage = imageFile;
          });
        } else {
          print("Error: Selected image file does not exist at ${image.path}");
          _showSnackbar("Selected image is invalid.", true);
        }
      } else {
        print("No image selected");
      }
    } catch (e) {
      print("Error picking image: $e");
      _showSnackbar("Failed to pick image. Please try again.", true);
    }
  }

  void _showSnackbar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

 

  // Updated _submitProfileDetails method to handle profile picture preservation
  Future<void> _submitProfileDetails() async {
    if (_formKey.currentState!.validate()) {
      if (_accessToken == null || _accessToken!.isEmpty) {
        print("Error: No access token available");
        _showSnackbar("Please log in again.", true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Registration()),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        var headers = {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'multipart/form-data',
        };

        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
            ApiConfig.shopkeeperProfileUrl,
          ),
        );

        // Add personal profile fields
        var personalProfileFields = {
          'personal_profile[phone_number]': _phoneController.text,
          'personal_profile[name]': _nameController.text,
          'personal_profile[email]': '', // Adjust if backend requires email
        };
        request.fields.addAll(personalProfileFields);

        // Add business profile fields if selected
        if (_includeBusinessProfile) {
          var businessProfileFields = {
            'business_profile[business_name]': _businessNameController.text,
            'business_profile[business_address]':
                _businessAddressController.text,
          };
          request.fields.addAll(businessProfileFields);
        }

        // Add profile picture if locally selected
        if (_profileImage != null) {
          var profilePicture = await http.MultipartFile.fromPath(
            'personal_profile[profile_picture]',
            _profileImage!.path,
          );
          request.files.add(profilePicture);
          print("Added local profile picture: ${_profileImage!.path}");
        }
        // If using existing URL, we might need to pass it separately
        // depending on backend requirements
        else if (_existingProfileImageUrl != null &&
            _existingProfileImageUrl!.isNotEmpty) {
          // Some APIs might accept a URL directly instead of a file upload
          // request.fields['personal_profile[profile_picture_url]'] = _existingProfileImageUrl!;
          print(
            "Keeping existing profile picture URL: $_existingProfileImageUrl",
          );
          // Note: Your backend needs to handle this case appropriately
        }

        request.headers.addAll(headers);
        print("Request fields: ${request.fields}");
        print("Request files: ${request.files.map((f) => f.field).toList()}");

        final appLanguage = Provider.of<AppLanguage>(context, listen: false);

        http.StreamedResponse response = await request.send();
        final responseBody = await response.stream.bytesToString();

        setState(() {
          _isLoading = false;
        });

        print("Response status: ${response.statusCode}");
        print("Response body: $responseBody");

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Profile updated successfully');

          // Parse the response to get updated profile data
          try {
            final responseData = jsonDecode(responseBody);

            // Update stored user data
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_name', _nameController.text);

            // Try to get the profile picture URL from the response
            String? updatedProfilePictureUrl;
            if (responseData != null &&
                responseData['personal_profile'] != null &&
                responseData['personal_profile']['profile_picture'] != null) {
              updatedProfilePictureUrl =
                  responseData['personal_profile']['profile_picture'];
              await prefs.setString(
                'user_profile_picture',
                updatedProfilePictureUrl!,
              );
              print("Updated profile picture URL: $updatedProfilePictureUrl");
            }
            // If we uploaded a local image but didn't get a URL back, we still need to
            // preserve the existing URL if the backend doesn't return the updated URL
            else if (_profileImage == null &&
                _existingProfileImageUrl != null &&
                _existingProfileImageUrl!.isNotEmpty) {
              // Keep the existing URL as we didn't change it
              print(
                "Keeping existing profile picture URL: $_existingProfileImageUrl",
              );
            }
          } catch (e) {
            print("Error parsing response data: $e");
          }

          // Show success message
          _showSnackbar(
            await appLanguage.translate(
              "Profile updated successfully!",
              appLanguage.currentLanguage,
            ),
            false,
          );

          // Navigate to business form page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BusinessFormPage()),
          );
        } else {
          print(
            'Profile update failed: ${response.statusCode} ${response.reasonPhrase}',
          );
          print('Error response: $responseBody');

          // Show error message
          _showSnackbar(
            await appLanguage.translate(
              "Failed to update profile: ${response.reasonPhrase}",
              appLanguage.currentLanguage,
            ),
            true,
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print("Profile update error: $e");

        final appLanguage = Provider.of<AppLanguage>(context, listen: false);
        _showSnackbar(
          await appLanguage.translate(
            "Connection error. Please check your internet connection.",
            appLanguage.currentLanguage,
          ),
          true,
        );
      }
    }
  }

  Widget _buildProfileImage() {
    // First priority: Show locally picked image if available
    if (_profileImage != null) {
      return Image.file(
        _profileImage!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Local image load error: $error");
          // Fall back to network image or default icon
          return _buildFallbackImage();
        },
      );
    }
    // Second priority: Show network image if URL is available
    else if (_existingProfileImageUrl != null) {
      return Image.network(
        _existingProfileImageUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              color: AppColors.secondaryBlue,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print("Network image load error: $error");
          // Fall back to default icon
          return Icon(Icons.person, size: 60, color: Colors.grey[400]);
        },
      );
    }
    // Default: Show placeholder icon
    else {
      return Icon(Icons.person, size: 60, color: Colors.grey[400]);
    }
  }

  Widget _buildFallbackImage() {
    // Try to show network image if URL is available
    if (_existingProfileImageUrl != null) {
      return Image.network(
        _existingProfileImageUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If network image also fails, show default icon
          return Icon(Icons.person, size: 60, color: Colors.grey[400]);
        },
      );
    } else {
      // Default icon as last resort
      return Icon(Icons.person, size: 60, color: Colors.grey[400]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          appLanguage.get('complete_profile'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Profile image picker
                 
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(child: _buildProfileImage()),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Instructions text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      appLanguage.get('profile_instructions'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Name field
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLanguage.get('name_required');
                      }
                      return null;
                    },
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: appLanguage.get('name'),
                      hintText: appLanguage.get('enter_full_name'),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: AppColors.secondaryBlue,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.lightBlue,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Phone number field
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLanguage.get('phone_required');
                      }
                      return null;
                    },
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: appLanguage.get('phone'),
                      hintText: appLanguage.get('enter_phone'),
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.secondaryBlue,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.lightBlue,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitProfileDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                appLanguage.get('save_profile'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 20), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
