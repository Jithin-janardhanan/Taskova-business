import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';


/// Model class to parse profile status response
class ProfileStatus {
  final bool isProfileComplete;
  final bool isApproved;
  final String role;
  final bool isEmailVerified;

  ProfileStatus({
    required this.isProfileComplete,
    required this.isApproved,
    required this.role,
    required this.isEmailVerified,
  });

  factory ProfileStatus.fromJson(Map<String, dynamic> json) {
    return ProfileStatus(
      isProfileComplete: json['is_profile_complete'] ?? false,
      isApproved: json['is_approved'] ?? false,
      role: json['role'] ?? "",
      isEmailVerified: json['is_email_verified'] ?? false,
    );
  }

  @override
  String toString() {
    return 'ProfileStatus(isProfileComplete: $isProfileComplete, isApproved: $isApproved, role: $role, isEmailVerified: $isEmailVerified)';
  }
}

/// Fetches the profile status from the API
///
/// Uses the token stored in SharedPreferences
/// @return A Future containing the parsed ProfileStatus object
Future<ProfileStatus?> getProfileStatus() async {
  try {
    // Get access token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null || accessToken.isEmpty) {
      print('No access token found in SharedPreferences');
      return null;
    }

    // Create the URI for the endpoint
    final uri = Uri.parse(ApiConfig.profileStatusUrl);

    // Set up headers with authorization
    final headers = {
      'Authorization': 'Bearer $accessToken',
    };

    // Create and send the request
    final request = http.Request('GET', uri);
    request.headers.addAll(headers);

    // Send the request and get the response
    final response = await request.send();

    // Check if the request was successful
    if (response.statusCode == 200) {
      // Convert response stream to string
      final responseBody = await response.stream.bytesToString();

      // Parse the JSON response
      final responseData = jsonDecode(responseBody);
      return ProfileStatus.fromJson(responseData);
    } else {
      print('Error: ${response.statusCode} - ${response.reasonPhrase}');
      return null;
    }
  } catch (e) {
    print('Request failed: $e');
    return null;
  }
}

/// Checks the profile status and navigates to the appropriate page
///
/// @param context The BuildContext for navigation
/// @param profileFillingPage The page to navigate to if profile is not complete
/// @param homePage The page to navigate to if profile is complete
Future<void> checkProfileStatusAndNavigate({
  required BuildContext context,
  required Widget profileFillingPage,
  required Widget homePage,
}) async {
  try {
    final profileStatus = await getProfileStatus();

    if (profileStatus == null) {
      // Handle error or token issues - stay on current page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch profile status'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate based on profile completion status
    if (profileStatus.isProfileComplete) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => homePage),
        (Route<dynamic> route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => profileFillingPage),
        (Route<dynamic> route) => false,
      );
    }
  } catch (e) {
    print('Error checking profile status: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error checking profile status'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
