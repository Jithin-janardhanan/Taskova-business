// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_shopkeeper/auth/login.dart';
// import 'package:taskova_shopkeeper/language/language_provider.dart';
// import 'package:taskova_shopkeeper/language/language_selection_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   try {
//     // Load environment variables with error handling
//     await dotenv.load(fileName: ".env").catchError((error) {
//       debugPrint("Error loading .env file: $error");
//       throw Exception("Failed to load environment variables");
//     });

//     // Print for debugging
//     print('Loaded BASE_URL: ${dotenv.env['BASE_URL']}');

//     // Initialize language provider
//     final prefs = await SharedPreferences.getInstance();
//     final appLanguage = AppLanguage();
//     await appLanguage.init();
//     final languageCode = prefs.getString('language_code');
//     final hasSelectedLanguage = languageCode != null && languageCode.isNotEmpty;

//     runApp(
//       ChangeNotifierProvider.value(
//         value: appLanguage,
//         child: MyApp(hasSelectedLanguage: hasSelectedLanguage),
//       ),
//     );
//   } catch (e) {
//     // Fallback UI if initialization fails
//     runApp(
//       MaterialApp(
//         home: Scaffold(
//           body: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, size: 50, color: Colors.red),
//                 const SizedBox(height: 20),
//                 Text("Initialization Error"),
//                 const SizedBox(height: 10),
//                 Text(e.toString(), textAlign: TextAlign.center),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () => main(), // Retry
//                   child: const Text("Retry"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class MyApp extends StatelessWidget {
//   final bool hasSelectedLanguage;

//   const MyApp({super.key, required this.hasSelectedLanguage});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Taskova',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: hasSelectedLanguage ? Login() : const LanguageSelectionScreen(),
//       // home: TestScreen(),
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/auth/login.dart';
import 'package:taskova_shopkeeper/language/language_provider.dart';
import 'package:taskova_shopkeeper/language/language_selection_screen.dart';
import 'package:taskova_shopkeeper/view/bottom_nav.dart';
import 'package:taskova_shopkeeper/Model/profile_status.dart';
import 'package:taskova_shopkeeper/auth/profile_page.dart';
import 'package:taskova_shopkeeper/view/busines%20management/business_detial_filling.dart';
import 'package:taskova_shopkeeper/view/verification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  try {
    // Load environment variables with error handling
    await dotenv.load(fileName: ".env").catchError((error) {
      debugPrint("Error loading .env file: $error");
      throw Exception("Failed to load environment variables");
    });

    // Print for debugging
    print('Loaded BASE_URL: ${dotenv.env['BASE_URL']}');

    // Initialize language provider
    final prefs = await SharedPreferences.getInstance();
    final appLanguage = AppLanguage();
    await appLanguage.init();
    final hasSelectedLanguage = prefs.containsKey('language_code');

    // Check if user is already logged in
    final bool isLoggedIn = await _checkUserLoginStatus();

    runApp(
      ChangeNotifierProvider.value(
        value: appLanguage,
        child: MyApp(
          hasSelectedLanguage: hasSelectedLanguage,
          isLoggedIn: isLoggedIn,
        ),
      ),
    );
  } catch (e) {
    // Fallback UI if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 20),
                Text("Initialization Error"),
                const SizedBox(height: 10),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(), // Retry
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Function to check user login status
Future<bool> _checkUserLoginStatus() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final userId = prefs.getString('user_id');

    // Check if both access token and user ID exist
    return accessToken != null &&
        accessToken.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty;
  } catch (e) {
    print("Error checking login status: $e");
    return false;
  }
}

class MyApp extends StatelessWidget {
  final bool hasSelectedLanguage;
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.hasSelectedLanguage,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    // If language not selected, show language selection
    if (!hasSelectedLanguage) {
      return const LanguageSelectionScreen();
    }

    // If not logged in, show login screen
    if (!isLoggedIn) {
      return Login();
    }

    // If logged in, show splash screen to determine next screen
    return const AppInitializationScreen();
  }
}

// Splash screen to handle navigation for logged-in users
class AppInitializationScreen extends StatefulWidget {
  const AppInitializationScreen({super.key});

  @override
  State<AppInitializationScreen> createState() =>
      _AppInitializationScreenState();
}

class _AppInitializationScreenState extends State<AppInitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Check profile status and navigate accordingly
      await checkAndNavigateBasedOnStatus(
        context: context,
        profileFillingPage: ProfileDetailFillingPage(),
        businessFillingPage: BusinessFormPage(),
        verificationPendingPage: VerificationPendingPage(),
        homePage: HomePageWithBottomNav(),
      );
    } catch (e) {
      print("Error during app initialization: $e");
      // If there's an error, navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Login()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
