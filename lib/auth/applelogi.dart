import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/Model/profile_status.dart';
import 'package:taskova_shopkeeper/auth/profile_filling.dart';
import 'package:taskova_shopkeeper/auth/registration.dart';
import 'package:taskova_shopkeeper/view/bottom_nav.dart';
import 'package:taskova_shopkeeper/view/busines%20management/business_detial_filling.dart';
import 'package:taskova_shopkeeper/view/verification.dart';
import '../language/language_provider.dart';

class AppleAuthService {
  
  /// Check if Apple Sign In is available on this device
  static Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }

  /// Handle Apple Sign In process
  Future<void> signInWithApple({
    required BuildContext context,
    required Function(String) showSuccessSnackbar,
    required Function(String) showErrorSnackbar,
    required Function(bool) setLoadingState,
  }) async {
    try {
      setLoadingState(true);

      // Check if Apple Sign In is available
      if (!await isAppleSignInAvailable()) {
        showErrorSnackbar('Apple Sign In is not available on this device');
        setLoadingState(false);
        return;
      }

      // Request Apple Sign In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.techfifo.taskova', // Replace with your actual client ID
          redirectUri: Uri.parse('https://your-domain.com/auth/apple'), // Replace with your redirect URI
        ),
      );

      // Extract user information
      String? identityToken = credential.identityToken;
      String? authorizationCode = credential.authorizationCode;
      String? email = credential.email;
      String? givenName = credential.givenName;
      String? familyName = credential.familyName;

      if (identityToken == null) {
        showErrorSnackbar('Apple Sign In failed: No identity token received');
        setLoadingState(false);
        return;
      }

      // Create full name from given and family names
      String fullName = '';
      if (givenName != null || familyName != null) {
        fullName = '${givenName ?? ''} ${familyName ?? ''}'.trim();
      }

      // Send to your backend
      await _sendAppleTokenToBackend(
        context: context,
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        email: email,
        fullName: fullName,
        showSuccessSnackbar: showSuccessSnackbar,
        showErrorSnackbar: showErrorSnackbar,
        setLoadingState: setLoadingState,
      );

    } on SignInWithAppleAuthorizationException catch (e) {
      setLoadingState(false);
      _handleAppleSignInError(e, showErrorSnackbar);
    } catch (e) {
      setLoadingState(false);
      print('Apple Sign In error: $e');
      showErrorSnackbar('Apple Sign In failed: ${e.toString()}');
    }
  }

  /// Send Apple identity token to backend
  Future<void> _sendAppleTokenToBackend({
    required BuildContext context,
    required String identityToken,
    String? authorizationCode,
    String? email,
    String? fullName,
    required Function(String) showSuccessSnackbar,
    required Function(String) showErrorSnackbar,
    required Function(bool) setLoadingState,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/social_auth/apple/'), // Adjust based on your API structure
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'identity_token': identityToken,
          'authorization_code': authorizationCode,
          'role': 'SHOPKEEPER', // or get this from user selection/default
          if (email != null) 'email': email,
          if (fullName != null) 'full_name': fullName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Apple Sign In Backend Response: $responseData');

        // Extract tokens and user data
        final tokens = responseData['tokens'];
        final user = responseData['user'];
        
        String accessToken = tokens['access'] ?? '';
        String refreshToken = tokens['refresh'] ?? '';
        String userId = user['id']?.toString() ?? '';
        String username = user['username'] ?? fullName ?? 'User';
        String userEmail = user['email'] ?? email ?? '';
        String role = user['role'] ?? 'SHOPKEEPER';
        bool isNewUser = responseData['is_new_user'] ?? false;

        // Save user data to SharedPreferences
        await _saveAppleUserData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          email: userEmail,
          username: username,
          userId: userId,
          role: role,
        );

        // Show success message
        showSuccessSnackbar(responseData['message'] ?? 'Apple Sign In successful!');

        // Navigate based on user status
        if (isNewUser) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Registration()),
            (Route<dynamic> route) => false,
          );
        } else {
          await checkAndNavigateBasedOnStatus(
  context: context,
  profileFillingPage: ProfileDetailFillingPage(),
  businessFillingPage: BusinessFormPage(),
  verificationPendingPage: VerificationPendingPage(),
  homePage: HomePageWithBottomNav(),
);

        }

      } else {
        setLoadingState(false);
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['error'] ?? 
                             errorData['detail'] ?? 
                             'Apple Sign In failed';
        showErrorSnackbar(errorMessage);
      }

    } catch (e) {
      setLoadingState(false);
      print('Backend Apple Sign In error: $e');
      showErrorSnackbar(
        Provider.of<AppLanguage>(context, listen: false).get('connection_error') ??
        'Connection error occurred'
      );
    }
  }

  /// Save Apple user data to SharedPreferences
  Future<void> _saveAppleUserData({
    required String accessToken,
    required String refreshToken,
    required String email,
    required String username,
    required String userId,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      print("Error: Attempting to save empty tokens");
      return;
    }

    print(
      "Saving Apple user data: access_token=$accessToken, refresh_token=$refreshToken, "
      "email=$email, username=$username, userId=$userId, role=$role",
    );

    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', username);
    await prefs.setString('user_id', userId);
    await prefs.setString('user_role', role);
    await prefs.setString('logged_in_email', email);
    await prefs.setString('login_method', 'apple');

    print("Saved Apple access_token: ${prefs.getString('access_token')}");
    print("Saved Apple user_id: ${prefs.getString('user_id')}");
  }

  /// Handle Apple Sign In specific errors
  void _handleAppleSignInError(
    SignInWithAppleAuthorizationException error, 
    Function(String) showErrorSnackbar
  ) {
    switch (error.code) {
      case AuthorizationErrorCode.canceled:
        showErrorSnackbar('Apple Sign In was canceled');
        break;
      case AuthorizationErrorCode.failed:
        showErrorSnackbar('Apple Sign In failed');
        break;
      case AuthorizationErrorCode.invalidResponse:
        showErrorSnackbar('Invalid response from Apple');
        break;
      case AuthorizationErrorCode.notHandled:
        showErrorSnackbar('Apple Sign In not handled');
        break;
      case AuthorizationErrorCode.unknown:
        showErrorSnackbar('Unknown Apple Sign In error');
        break;
      default:
        showErrorSnackbar('Apple Sign In error: ${error.message}');
    }
  }
}