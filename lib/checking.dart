// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:lottie/lottie.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_shopkeeper/Model/api_config.dart';
// import 'package:taskova_shopkeeper/Model/colors.dart';
// import 'package:taskova_shopkeeper/Model/profile_status.dart';
// import 'package:taskova_shopkeeper/Model/validator.dart';
// import 'package:taskova_shopkeeper/auth/forgot_password.dart';
// import 'package:taskova_shopkeeper/auth/google.dart';
// import 'package:taskova_shopkeeper/auth/profile_page.dart';
// import 'package:taskova_shopkeeper/language/language_selection_screen.dart';
// import 'package:taskova_shopkeeper/view/bottom_nav.dart';
// import '../language/language_provider.dart';
// import 'registration.dart';
// import 'package:http/http.dart' as http;

// class Login extends StatefulWidget {
//   const Login({super.key});
//   @override
//   State<Login> createState() => _LoginState();
// }

// class _LoginState extends State<Login> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _passwordVisible = false;
//   bool _isLoading = false;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//   // Create an instance of the GoogleAuthService
//   final GoogleAuthService _googleAuthService = GoogleAuthService();

//    @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void showSuccessSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green.shade700,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   void showErrorSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red.shade700,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   void setLoadingState(bool isLoading) {
//     setState(() {
//       _isLoading = isLoading;
//     });
//   }

//   Future<void> _handleGoogleLogin() async {
//     await _googleAuthService.signInWithGoogle(
//       context: context,
//       showSuccessSnackbar: showSuccessSnackbar,
//       showErrorSnackbar: showErrorSnackbar,
//       setLoadingState: setLoadingState,
//     );
//   }

//   // Removed showSuccessSnackbar function since we don't want to show success messages

//   Future<void> saveTokens(String accessToken, String refreshToken, String email,
//       String name) async {
//     final prefs = await SharedPreferences.getInstance();
//     if (accessToken.isEmpty || refreshToken.isEmpty) {
//       print("Error: Attempting to save empty tokens");
//       return;
//     }
//     print(
//         "Saving tokens: access_token=$accessToken, refresh_token=$refreshToken, email=$email, name=$name");
//     await prefs.setString('access_token', accessToken);
//     await prefs.setString('refresh_token', refreshToken);
//     await prefs.setString('user_email', email);
//     await prefs.setString('user_name', name);
//     print("Saved access_token: ${prefs.getString('access_token')}");
//   }

//   Future<void> loginUser() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         final response = await http.post(
//           Uri.parse(ApiConfig.loginUrl),
//           headers: {
//             'Content-Type': 'application/json',
//           },
//           body: jsonEncode({
//             'email': _emailController.text,
//             'password': _passwordController.text,
//             'remember_me': true,
//           }),
//         );

//         if (response.statusCode == 200 || response.statusCode == 201) {
//           // Login successful
//           Map<String, dynamic> responseData = jsonDecode(response.body);
//           print("Login response: $responseData"); // Log response

//           // Store tokens in SharedPreferences
//           String accessToken = responseData['access'] ?? "";
//           String refreshToken = responseData['refresh'] ?? "";
//           String name = responseData['name'] ?? "User";
//           bool isNewUser = responseData['is_new_user'] ?? false;

//           await saveTokens(
//               accessToken, refreshToken, _emailController.text, name);

//           // Keep loading state true while navigating
//           // Navigation will happen with loading indicator still visible

//           if (isNewUser) {
//             // If email is not already registered, navigate to registration
//             Navigator.pushAndRemoveUntil(
//               context,
//               MaterialPageRoute(builder: (context) => Registration()),
//               (Route<dynamic> route) => false,
//             );
//           } else {
//             // If email is already registered, check profile status and navigate
//             await checkProfileStatusAndNavigate(
//               context: context,
//               profileFillingPage: ProfileDetailFillingPage(),
//               homePage: HomePageWithBottomNav(),
//             );
//           }
//           // Note: We don't set _isLoading to false since we're navigating away
//         } else {
//           // Login failed
//           setState(() {
//             _isLoading = false;
//           });
//           Map<String, dynamic> errorData = jsonDecode(response.body);
//           String errorMessage = errorData['detail'] ??
//               Provider.of<AppLanguage>(context, listen: false)
//                   .get('login_failed');
//           showErrorSnackbar(errorMessage);
//         }
//       } catch (e) {
//         setState(() {
//           _isLoading = false;
//         });
//         print("Login error: $e");
//         showErrorSnackbar(Provider.of<AppLanguage>(context, listen: false)
//             .get('connection_error'));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final appLanguage = Provider.of<AppLanguage>(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   const SizedBox(height: 20),
//                   // Language switcher button
//                   Align(
//                     alignment: Alignment.topRight,
//                     child: TextButton.icon(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 const LanguageSelectionScreen(),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.language,
//                           color: AppColors.secondaryBlue),
//                       label: Text(
//                         appLanguage.get('change_language'),
//                         style: const TextStyle(color: AppColors.secondaryBlue),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   // App Logo
//                   Container(
//                     height: 100,
//                     width: 100,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Lottie.asset(
//                       'assets/login_lottie.json',
//                       height: 60,
//                       width: 60,
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   // App name
//                   Text(
//                     appLanguage.get('app_name'),
//                     style: const TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.primaryBlue,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   // Tagline
//                   Text(
//                     appLanguage.get('tagline'),
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 50),
//                   // Email field
//                   TextFormField(
//                     validator: validateEmail,
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: InputDecoration(
//                       hintText: appLanguage.get('email_hint'),
//                       prefixIcon: const Icon(
//                         Icons.email_outlined,
//                         color: AppColors.secondaryBlue,
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey[50],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(
//                             color: AppColors.lightBlue, width: 1),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(
//                             color: AppColors.primaryBlue, width: 2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   // Password field
//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: !_passwordVisible,
//                     decoration: InputDecoration(
//                       hintText: appLanguage.get('password_hint'),
//                       prefixIcon: const Icon(
//                         Icons.lock_outline,
//                         color: AppColors.secondaryBlue,
//                       ),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _passwordVisible
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                           color: AppColors.secondaryBlue,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _passwordVisible = !_passwordVisible;
//                           });
//                         },
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey[50],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(
//                             color: AppColors.lightBlue, width: 1),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(
//                             color: AppColors.primaryBlue, width: 2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   // Forgot password
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: TextButton(
//                       onPressed: () => navigateToForgotPasswordScreen(context),
//                       child: Text(
//                         appLanguage.get('forgot_password'),
//                         style: const TextStyle(
//                           color: AppColors.secondaryBlue,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   // Login button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton(
//                       onPressed: _isLoading
//                           ? null
//                           : () {
//                               if (_formKey.currentState!.validate()) {
//                                 loginUser();
//                               }
//                             },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryBlue,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: _isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : Text(
//                               appLanguage.get('login'),
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   // Or divider
//                   Row(
//                     children: [
//                       Expanded(child: Divider(color: Colors.grey[300])),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Text(
//                           appLanguage.get('or_continue_with'),
//                           style:
//                               TextStyle(color: Colors.grey[600], fontSize: 12),
//                         ),
//                       ),
//                       Expanded(child: Divider(color: Colors.grey[300])),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   // Social login buttons
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Google login
//                       _socialLoginButton(
//                         onPressed: _isLoading
//                             ? null
//                             : () {
//                                 _handleGoogleLogin();
//                               },
//                         icon: Icons.g_mobiledata,
//                         label: appLanguage.get('google'),
//                         backgroundColor: Colors.white,
//                         textColor: Colors.black87,
//                       ),
//                       const SizedBox(width: 16),
//                       // Apple login
//                       _socialLoginButton(
//                         onPressed: _isLoading
//                             ? null
//                             : () {

//                               },
//                         icon: Icons.apple,
//                         label: appLanguage.get('apple'),
//                         backgroundColor: Colors.black,
//                         textColor: Colors.white,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   // Register link
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         appLanguage.get('dont_have_account'),
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                       TextButton(
//                         onPressed: _isLoading
//                             ? null
//                             : () {
//                                 Navigator.pushReplacement(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => Registration(),
//                                   ),
//                                 );
//                               },
//                         child: Text(
//                           appLanguage.get('sign_up'),
//                           style: const TextStyle(
//                             color: AppColors.primaryBlue,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _socialLoginButton({
//     required VoidCallback? onPressed,
//     required IconData icon,
//     required String label,
//     required Color backgroundColor,
//     required Color textColor,
//   }) {
//     return SizedBox(
//       width: 150,
//       height: 50,
//       child: ElevatedButton.icon(
//         onPressed: onPressed,
//         icon: Icon(icon, color: textColor),
//         label: Text(
//           label,
//           style: TextStyle(color: textColor),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: backgroundColor,
//           foregroundColor: textColor,
//           elevation: 0,
//           side: BorderSide(color: Colors.grey[300]!),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       ),
//     );
//   }
// }

// void navigateToForgotPasswordScreen(BuildContext context) {
//   Navigator.push(
//     context,
//     MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
//   );
// }