import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/Model/colors.dart';
import 'package:taskova_shopkeeper/Model/postcode.dart';
import 'package:taskova_shopkeeper/language/language_provider.dart';
import 'package:taskova_shopkeeper/view/verification.dart';

class BusinessFormPage extends StatefulWidget {
  const BusinessFormPage({super.key});

  @override
  State<BusinessFormPage> createState() => _BusinessFormPageState();
}

class _BusinessFormPageState extends State<BusinessFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _postcodeController = TextEditingController();

  File? _businessImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _accessToken;
  String? _userId;
  final bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accessToken = prefs.getString('access_token');
      _userId = prefs.getString('user_id');
      final savedEmail = prefs.getString('user_email');
      if (savedEmail != null) {
        _emailController.text = savedEmail;
      }
    });
  }

  void _onAddressSelected(double latitude, double longitude, String address) {
    setState(() {
      _latitudeController.text = latitude.toString();
      _longitudeController.text = longitude.toString();
      _businessAddressController.text = address;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedImage != null) {
        final File imageFile = File(pickedImage.path);
        final fileSize = await imageFile.length();
        setState(() {
          _businessImage = imageFile;
        });
        if (fileSize > 2 * 1024 * 1024) {
          _showSnackbar(
            "Selected image is large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). This might cause slower uploads.",
            false,
          );
        }
      }
    } catch (e) {
      _showSnackbar("Error selecting image: $e", true);
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

  Future<bool> _verifyImageFile() async {
    if (_businessImage == null) return true; // Image is optional
    try {
      final exists = await _businessImage!.exists();
      if (!exists) {
        _showSnackbar("Image file doesn't exist", true);
        return false;
      }
      final fileSize = await _businessImage!.length();
      if (fileSize > 5 * 1024 * 1024) {
        _showSnackbar(
          "Image is too large. Please select an image under 5MB.",
          true,
        );
        return false;
      }
      final fileExtension = _businessImage!.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif'];
      if (!validExtensions.contains(fileExtension)) {
        _showSnackbar("Please select a valid image file (JPG, PNG, GIF)", true);
        return false;
      }
      return true;
    } catch (e) {
      _showSnackbar("Error verifying image file: $e", true);
      return false;
    }
  }

  Future<void> _submitBusinessDetails() async {
    if (_formKey.currentState!.validate()) {
      if (_businessImage != null) {
        final imageValid = await _verifyImageFile();
        if (!imageValid) return;
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
          Uri.parse(ApiConfig.regiserBusiness),
        );
        request.fields.addAll({
          'name': _businessNameController.text,
          'address': _businessAddressController.text,
          'email': _emailController.text,
          'contact_number': _contactNumberController.text,
          'latitude': _latitudeController.text,
          'longitude': _longitudeController.text,
          'postcode': _postcodeController.text,
          'is_active': _isActive.toString(),
          'user': _userId ?? '',
        });

        if (_businessImage != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', _businessImage!.path),
          );
        }

        request.headers.addAll(headers);
        final appLanguage = Provider.of<AppLanguage>(context, listen: false);

        http.StreamedResponse response = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException("Request timed out");
          },
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSnackbar(
            await appLanguage.translate(
              "Business profile created successfully!",
              appLanguage.currentLanguage,
            ),
            false,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VerificationPendingPage()),
          );
        } else {
          final errorResponse = await response.stream.bytesToString();
          String errorMessage =
              "Failed to create business profile. Please try again.";
          try {
            final errorData = json.decode(errorResponse);
            errorMessage =
                errorData['error'] ?? errorData['message'] ?? errorMessage;
          } catch (e) {
            // Handle non-JSON response
          }
          _showSnackbar(
            await appLanguage.translate(
              errorMessage,
              appLanguage.currentLanguage,
            ),
            true,
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        String errorMessage =
            "Connection error. Please check your internet connection.";
        if (e is TimeoutException) {
          errorMessage = "Request timed out. Please try again.";
        }
        final appLanguage = Provider.of<AppLanguage>(context, listen: false);
        _showSnackbar(
          await appLanguage.translate(
            errorMessage,
            appLanguage.currentLanguage,
          ),
          true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          appLanguage.get('business details') ?? 'Business Details',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
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
                    // Business image picker
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
                            child:
                                _businessImage != null
                                    ? ClipOval(
                                      child: Image.file(
                                        _businessImage!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Icon(
                                      Icons.business,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                        appLanguage.get('business_instructions') ??
                            'Please fill in the details of your business',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Business Name field
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLanguage.get('business_name_required') ??
                              'Business name is required';
                        }
                        return null;
                      },
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        labelText:
                            appLanguage.get('business_name') ?? 'Business Name',
                        hintText:
                            appLanguage.get('enter_business_name') ??
                            'Enter your business name',
                        prefixIcon: const Icon(
                          Icons.business,
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
                    // Email field
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLanguage.get('email_required') ??
                              'Email is required';
                        }
                        if (!value.contains('@')) {
                          return appLanguage.get('valid_email_required') ??
                              'Please enter a valid email';
                        }
                        return null;
                      },
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: appLanguage.get('email') ?? 'Email',
                        hintText:
                            appLanguage.get('enter_email') ??
                            'Enter business email',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
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
                    // Contact Number field
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLanguage.get('phone_required');
                        }
                        // Basic UK phone validation - check length and starts with valid digits
                        String cleanPhone = value.replaceAll(
                          RegExp(r'[^\d]'),
                          '',
                        );
                        if (cleanPhone.length < 10 || cleanPhone.length > 11) {
                          return 'Enter a valid UK phone number';
                        }
                        if (!cleanPhone.startsWith('0') &&
                            !cleanPhone.startsWith('44')) {
                          return 'Enter a valid UK phone number';
                        }
                        return null;
                      },
                      controller: _contactNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: appLanguage.get('phone'),
                        hintText: '07123456789',
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🇬🇧', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.phone_outlined,
                                color: AppColors.secondaryBlue,
                              ),
                            ],
                          ),
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
                    // Postcode Search Widget
                    PostcodeSearchWidget(
                      postcodeController: _postcodeController,
                      onAddressSelected: _onAddressSelected,
                      placeholderText:
                          appLanguage.get('postcode') ?? 'Postcode',
                    ),
                    const SizedBox(height: 20),
                    // Business Address field
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLanguage.get('business_address_required') ??
                              'Business address is required';
                        }
                        return null;
                      },
                      controller: _businessAddressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText:
                            appLanguage.get('business_address') ??
                            'Business Address',
                        hintText:
                            appLanguage.get('enter_business_address') ??
                            'Enter your business address',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: AppColors.secondaryBlue,
                          ),
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
                    // Is Active switch
                    // Container(
                    //   padding: const EdgeInsets.symmetric(vertical: 5),
                    //   height: 60,
                    //   decoration: BoxDecoration(
                    //     color: Colors.grey[50],
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(
                    //       color: AppColors.lightBlue,
                    //       width: 1,
                    //     ),
                    //   ),
                    //   child: SwitchListTile(
                    //     title: Text(
                    //       appLanguage.get('active') ?? 'Active',
                    //       style: const TextStyle(
                    //         fontSize: 14,
                    //         color: AppColors.secondaryBlue,
                    //       ),
                    //     ),
                    //     value: _isActive,
                    //     onChanged: (bool value) {
                    //       setState(() {
                    //         _isActive = value;
                    //       });
                    //     },
                    //     activeColor: AppColors.primaryBlue,
                    //     contentPadding: const EdgeInsets.symmetric(
                    //       horizontal: 16,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 40),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitBusinessDetails,
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
                                  appLanguage.get('save business') ??
                                      'Save Business',
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
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }
}
