import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'login.dart';

class LogoutService {
  // Singleton pattern
  static final LogoutService _instance = LogoutService._internal();

  factory LogoutService() {
    return _instance;
  }

  LogoutService._internal();

  // Show success snackbar
  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Show error snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Show confirmation dialog with Lottie animation
  Future<bool> _showLogoutConfirmationDialog(
    BuildContext context, {
    String imagePath = 'assets/logout.png',
  }) async {
    bool confirmLogout = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 16),
              Text('Are you sure you want to logout?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                confirmLogout = false;
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                confirmLogout = true;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    return confirmLogout;
  }

  // Show loading dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Logging out..."),
            ],
          ),
        );
      },
    );
  }

  // Logout function that calls the API
  Future<void> logout(
    BuildContext context, {
    String imagePath = 'assets/logout.png',
  }) async {
    // First show confirmation dialog
    bool confirmLogout = await _showLogoutConfirmationDialog(
      context,
      imagePath: imagePath,
    );

    if (!confirmLogout) {
      return; // User cancelled the logout
    }

    try {
      // Show loading dialog
      _showLoadingDialog(context);

      // Get tokens from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? "";
      final refreshToken = prefs.getString('refresh_token') ?? "";

      // Call logout API
      final response = await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      // Close the loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 205) {
        // Successfully logged out from server
        Map<String, dynamic> responseData = {};
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          // If the response body isn't valid JSON, ignore the error
        }

        String successMessage =
            responseData['message'] ?? "Logged out successfully";
        print("Logged out successfully from server: $successMessage");

        // Show success snackbar
        _showSuccessSnackbar(context, successMessage);

        // Clear stored tokens
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_email');
        await prefs.remove('user_name');

        // Wait a moment to show the snackbar before navigating
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (Route<dynamic> route) => false,
        );
      } else {
        print("Logout API error: ${response.statusCode} ${response.body}");

        // Show error message
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          // If the response body isn't valid JSON, ignore the error
        }

        String errorMessage =
            errorData['detail'] ?? "Logout failed. Please try again.";
        _showErrorSnackbar(context, errorMessage);

        // We'll still clear tokens and redirect to login page even if the API call fails
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_email');
        await prefs.remove('user_name');

        // Wait a moment to show the snackbar before navigating
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Close the loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print("Error during logout: $e");

      // Show error message
      _showErrorSnackbar(context, "Logout failed. Please try again.");

      // Try to clear tokens locally anyway
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_email');
        await prefs.remove('user_name');

        // Wait a moment to show the snackbar before navigating
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        print("Error clearing SharedPreferences: $e");
      }
    }
  }
}
