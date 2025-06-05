// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_shopkeeper/auth/login.dart';
// import 'package:taskova_shopkeeper/language/language_selection_screen.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }

//   Future<void> _initializeApp() async {
//     try {
//       // Add a minimum splash duration for better UX
//       await Future.delayed(const Duration(seconds: 2));
      
//       // Check initialization status
//       final prefs = await SharedPreferences.getInstance();
      
//       // Check if language is selected
//       final languageCode = prefs.getString('language_code');
//       final hasSelectedLanguage = languageCode != null && languageCode.isNotEmpty;
      
//       // Check if user is logged in
//       final isLoggedIn = await _checkUserLoginStatus(prefs);
      
//       if (!mounted) return;
      
//       // Navigate based on status
//       if (!hasSelectedLanguage) {
//         _navigateToLanguageSelection();
//       } else if (!isLoggedIn) {
//         _navigateToLogin();
//       } else {
//         _navigateToHome();
//       }
//     } catch (e) {
//       if (!mounted) return;
//       _showErrorAndRetry(e.toString());
//     }
//   }

//   Future<bool> _checkUserLoginStatus(SharedPreferences prefs) async {
//     // Check various authentication tokens/flags
//     // Modify these keys according to your app's authentication logic
//     final authToken = prefs.getString('auth_token');
//     final userId = prefs.getString('user_id');
//     final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
//     // You can add more sophisticated checks like token validation
//     return authToken != null && authToken.isNotEmpty && isLoggedIn;
//   }

//   void _navigateToLanguageSelection() {
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (context) => const LanguageSelectionScreen(),
//       ),
//     );
//   }

//   void _navigateToLogin() {
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (context) => Login(),
//       ),
//     );
//   }

//   void _navigateToHome() {
//     // Replace this with your main/home screen
//     // For now, navigating to Login as a placeholder
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (context) => Login(), // Replace with your HomeScreen
//       ),
//     );
//   }

//   void _showErrorAndRetry(String error) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Initialization Error'),
//         content: Text(error),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _initializeApp();
//             },
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Taskova Logo
//             Container(
//               width: 280,
//               height: 120,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 20,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(15),
//                 child: Image.asset(
//                   'assets/images/taskova_logo.png', // Add your logo image to assets folder
//                   fit: BoxFit.contain,
//                   errorBuilder: (context, error, stackTrace) {
//                     // Fallback if image not found
//                     return Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(15),
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: const Center(
//                         child: Text(
//                           'taskova',
//                           style: TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF4A4A95), // Purple color from logo
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(height: 40),
            
//             // Subtitle
//             const Text(
//               'Shopkeeper',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF4A4A95),
//               ),
//             ),
//             const SizedBox(height: 60),
            
//             // Loading indicator
//             const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A4A95)),
//               strokeWidth: 3,
//             ),
//             const SizedBox(height: 25),
            
//             // Loading text
//             const Text(
//               'Initializing...',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey,
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }