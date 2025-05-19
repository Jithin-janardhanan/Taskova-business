// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;

// import 'package:provider/provider.dart';
// import 'package:taskova_shopkeeper/Model/api_config.dart';
// import 'package:taskova_shopkeeper/Model/profile_status.dart';
// import 'package:taskova_shopkeeper/auth/profile_page.dart';
// import 'package:taskova_shopkeeper/auth/registration.dart';
// import 'package:taskova_shopkeeper/view/bottom_nav.dart';

// import '../language/language_provider.dart';

// class GoogleAuthService {
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   // This function handles the Google sign-in flow
//   Future<void> signInWithGoogle({
//     required BuildContext context,
//     required Function(String) showSuccessSnackbar,
//     required Function(String) showErrorSnackbar,
//     required Function(bool) setLoadingState,
//   }) async {
//     setLoadingState(true);

//     try {
//       // Sign out first to ensure the account picker shows every time
//       await _googleSignIn.signOut();

//       // Trigger the authentication flow with account selection
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) {
//         // User canceled the sign-in process
//         setLoadingState(false);
//         return;
//       }

//       // Get authentication token
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;
//       final String? idToken = googleAuth.idToken;

//       if (idToken == null) {
//         setLoadingState(false);
//         showErrorSnackbar(
//           Provider.of<AppLanguage>(
//             context,
//             listen: false,
//           ).get('authentication_failed'),
//         );
//         return;
//       }

//       // Send the token to your backend
//       final response = await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/social_auth/google/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'auth_token': idToken}),
//       );

//       setLoadingState(false);

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // Authentication successful
//         Map<String, dynamic> responseData = jsonDecode(response.body);
//         print("Google login response: $responseData"); // Log response

//         // Extract tokens from nested auth_token.tokens
//         String accessToken =
//             responseData['auth_token']?['tokens']?['access'] ?? "";
//         String refreshToken =
//             responseData['auth_token']?['tokens']?['refresh'] ?? "";
//         String name =
//             responseData['auth_token']?['username'] ??
//             googleUser.displayName ??
//             "User";
//         bool isNewUser = responseData['is_new_user'] ?? false;

//         // Extract profile picture URL from response if available
//         String? profilePicture;

//         // Try to get profile picture from the response first
//         if (responseData['auth_token']?['photo_url'] != null) {
//           profilePicture = responseData['auth_token']['photo_url'];
//         }
//         // If not available in response, try to parse the ID token to get the picture
//         else {
//           try {
//             // Parse the ID token (it's a JWT)
//             final parts = idToken.split('.');
//             if (parts.length >= 2) {
//               // Decode the payload part (the middle part)
//               String normalizedPayload = base64Url.normalize(parts[1]);
//               String decodedPayload = utf8.decode(
//                 base64Url.decode(normalizedPayload),
//               );
//               Map<String, dynamic> payload = jsonDecode(decodedPayload);

//               // Extract the picture URL from the token payload
//               if (payload.containsKey('picture')) {
//                 profilePicture = payload['picture'];
//                 print("Found profile picture in ID token: $profilePicture");
//               }
//             }
//           } catch (e) {
//             print("Error parsing ID token for picture: $e");
//           }
//         }

//         // Fallback to photoUrl from GoogleSignInAccount if available
//         if (profilePicture == null && googleUser.photoUrl != null) {
//           profilePicture = googleUser.photoUrl;
//           print("Using Google account photo URL: $profilePicture");
//         }

//         await _saveTokens(
//           accessToken,
//           refreshToken,
//           googleUser.email,
//           name,
//           profilePicture,
//         );

//         final appLanguage = Provider.of<AppLanguage>(context, listen: false);
//         showSuccessSnackbar(
//           await appLanguage.translate(
//             "Google login successful!",
//             appLanguage.currentLanguage,
//           ),
//         );

//         if (isNewUser) {
//           // If email is not already registered, navigate to registration
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (context) => Registration()),
//             (Route<dynamic> route) => false,
//           );
//         } else {
//           // If email is already registered, check profile status and navigate
//           await checkProfileStatusAndNavigate(
//             context: context,
//             profileFillingPage: ProfileDetailFillingPage(),
//             homePage: HomePageWithBottomNav(),
//           );
//         }
//       } else {
//         // Authentication failed
//         Map<String, dynamic> errorData = jsonDecode(response.body);
//         String errorMessage =
//             errorData['detail'] ??
//             Provider.of<AppLanguage>(
//               context,
//               listen: false,
//             ).get('login_failed');
//         showErrorSnackbar(errorMessage);
//       }
//     } catch (e) {
//       setLoadingState(false);
//       print("Google login error: $e");
//       showErrorSnackbar(
//         Provider.of<AppLanguage>(
//           context,
//           listen: false,
//         ).get('connection_error'),
//       );
//     }
//   }

//   // Helper method to save authentication tokens and user info
//   Future<void> _saveTokens(
//     String accessToken,
//     String refreshToken,
//     String email,
//     String name,
//     String? profilePicture,
//   ) async {
//     final prefs = await SharedPreferences.getInstance();
//     if (accessToken.isEmpty || refreshToken.isEmpty) {
//       print("Error: Attempting to save empty tokens");
//       return;
//     }

//     print(
//       "Saving tokens: access_token=$accessToken, refresh_token=$refreshToken, email=$email, name=$name, profile_picture=$profilePicture",
//     );

//     await prefs.setString('access_token', accessToken);
//     await prefs.setString('refresh_token', refreshToken);
//     await prefs.setString('user_email', email);
//     await prefs.setString('user_name', name);

//     // Save profile picture URL if available
//     if (profilePicture != null && profilePicture.isNotEmpty) {
//       await prefs.setString('user_profile_picture', profilePicture);
//       print("Saved profile picture URL: $profilePicture");
//     }

//     print("Saved access_token: ${prefs.getString('access_token')}");
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/Model/profile_status.dart';
import 'package:taskova_shopkeeper/auth/profile_page.dart';
import 'package:taskova_shopkeeper/auth/registration.dart';
import 'package:taskova_shopkeeper/view/bottom_nav.dart';
import '../language/language_provider.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // This function handles the Google sign-in flow with the new API endpoint
  Future<void> signInWithGoogle({
    required BuildContext context,
    required Function(String) showSuccessSnackbar,
    required Function(String) showErrorSnackbar,
    required Function(bool) setLoadingState,
  }) async {
    setLoadingState(true);

    try {
      // Sign out first to ensure the account picker shows every time
      await _googleSignIn.signOut();

      // Trigger the authentication flow with account selection
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in process
        setLoadingState(false);
        return;
      }

      // Make request to the new API endpoint
      final response = await http.post(
        Uri.parse(ApiConfig.googleUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': googleUser.email,
          'role': 'SHOPKEEPER', // Add role parameter as required
        }),
      );

      if (response.statusCode == 200) {
        // Successfully authenticated
        final responseData = jsonDecode(response.body);
        print("Google login response: $responseData");

        // Extract data from the new response format
        final userData = responseData['user'];
        final tokens = responseData['tokens'];

        // Get profile picture from Google account
        String? profilePicture = googleUser.photoUrl;

        // Save user data to SharedPreferences
        await _saveUserData(
          accessToken: tokens['access'],
          refreshToken: tokens['refresh'],
          email: userData['email'],
          username: userData['username'],
          userId: userData['id'].toString(),
          role: userData['role'],
          profilePicture: profilePicture,
        );

        setLoadingState(false);

        // Show success message
        final appLanguage = Provider.of<AppLanguage>(context, listen: false);
        showSuccessSnackbar(
          await appLanguage.translate(
            responseData['message'] ?? "Google login successful!",
            appLanguage.currentLanguage,
          ),
        );

        // Determine if this is a new user based on response data
        // Since your new API doesn't explicitly return is_new_user, you might need to
        // implement your own logic or check with your backend team
        bool isNewUser = responseData['is_new_user'] ?? false;

        if (isNewUser) {
          // If email is not already registered, navigate to registration
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Registration()),
            (Route<dynamic> route) => false,
          );
        } else {
          // If email is already registered, check profile status and navigate
          await checkProfileStatusAndNavigate(
            context: context,
            profileFillingPage: ProfileDetailFillingPage(),
            homePage: HomePageWithBottomNav(),
          );
        }
      } else {
        setLoadingState(false);
        // Authentication failed
        Map<String, dynamic> errorData = jsonDecode(response.body);
        String errorMessage =
            errorData['detail'] ??
            errorData['error'] ??
            Provider.of<AppLanguage>(
              context,
              listen: false,
            ).get('login_failed');
        showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      setLoadingState(false);
      print("Google login error: $e");
      showErrorSnackbar(
        Provider.of<AppLanguage>(
          context,
          listen: false,
        ).get('connection_error'),
      );
    }
  }

  // Helper method to save authentication tokens and user info
  Future<void> _saveUserData({
    required String accessToken,
    required String refreshToken,
    required String email,
    required String username,
    required String userId,
    required String role,
    String? profilePicture,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      print("Error: Attempting to save empty tokens");
      return;
    }

    print(
      "Saving user data: access_token=$accessToken, refresh_token=$refreshToken, " +
          "email=$email, username=$username, userId=$userId, role=$role, " +
          "profile_picture=$profilePicture",
    );

    // Save all the necessary user data
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', username);
    await prefs.setString('user_id', userId);
    await prefs.setString('user_role', role);
    await prefs.setString(
      'logged_in_email',
      email,
    ); // For consistency with existing code

    // Save profile picture URL if available
    if (profilePicture != null && profilePicture.isNotEmpty) {
      await prefs.setString('user_profile_picture', profilePicture);
      print("Saved profile picture URL: $profilePicture");
    }

    print("Saved access_token: ${prefs.getString('access_token')}");
  }
}
