import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

class AppLanguage extends ChangeNotifier {
  // Instance of translator
  final GoogleTranslator _translator = GoogleTranslator();

  // Map to store translations for current language
  Map<String, String> _translations = {};

  // Current language code
  String _currentLanguage = 'en';

  // Get current language
  String get currentLanguage => _currentLanguage;

  // List of supported languages
  final List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
    {'code': 'pl', 'name': 'Polish', 'nativeName': 'Polski'},
    {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
    {'code': 'ro', 'name': 'Romanian', 'nativeName': 'Română'},
    {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch'},
  ];

  // Default strings (English)
  final Map<String, String> _defaultStrings = {
    'app_name': 'Taskova',
    'tagline': 'Organize your delivery efficiently',
    'email_hint': 'Email address',
    'password_hint': 'Password',
    'forgot_password': 'Forgot password?',
    'login': 'Log In',
    'or_continue_with': 'Or continue with',
    'google': 'Google',
    'dont_have_account': "Don't have an account?",
    'sign_up': 'Sign Up',
    'select_language': 'Select your preferred language',
    'continue_text': 'Continue',
    'change_language': 'Change Language',
    'connection_error':
        'Connection error. Please check your internet connection.',
    'login_failed': 'Login failed. Please check your credentials.',
    "register": "Register",
    "_email": "Email",
    "password": "Password",
    "confirm_password": "Confirm Password",
    "continue": "Continue",
    "Already_have_an_account": "Already have an account?",
    "Log_in": "Login",
    "join_taskova": "Join taskova",
    "registration_failed": "Registration failed. Please try again.",
    "create_an_account": "create an account to get started",
    "Create_account": "Create account",
    'complete_profile': 'Complete Profile',
    'profile_instructions':
        'Please complete your profile information to continue',
    'name': 'Name',
    'enter_full_name': 'Enter your full name',
    'name_required': 'Name is required',
    'phone': 'Phone Number',
    'enter_phone': 'Enter your phone number',
    'phone_required': 'Phone number is required',
    'include_business_profile': 'Include Business Profile',
    'business_name': 'Business Name',
    'enter_business_name': 'Enter your business name',
    'business_name_required': 'Business name is required',
    'business_address': 'Business Address',
    'enter_business_address': 'Enter your business address',
    'business_address_required': 'Business address is required',
    'save_profile': 'Save Profile',
    'skip_for_now': 'Skip for now',
    'profile_updated_successfully': 'Profile updated successfully!',
    'failed_to_update_profile': 'Failed to update profile. Please try again.',
    'business_details': 'Business Details',
'business_instructions': 'Please fill in the details of your business',
'business_name': 'Business Name',
'enter_business_name': 'Enter your business name',
'business_name_required': 'Business name is required',
'business_address': 'Business Address',
'enter_business_address': 'Enter your business address',
'business_address_required': 'Business address is required',
'email': 'Email',
'enter_email': 'Enter business email',
'email_required': 'Email is required',
'valid_email_required': 'Please enter a valid email',
'contact_number': 'Contact Number',
'enter_contact_number': 'Enter business contact number',
'contact_number_required': 'Contact number is required',
'postcode': 'Postcode',
'enter_postcode': 'Enter postcode',
'postcode_required': 'Postcode is required',
'please_enter_postcode': 'Please enter a postcode first',
'fetch_coordinates': 'Fetch coordinates from postcode',
'active': 'Active',
'latitude': 'Latitude',
'enter_latitude': 'Enter latitude',
'longitude': 'Longitude',
'enter_longitude': 'Enter longitude',
'save_business': 'Save Business',
'skip_for_now': 'Skip for now',
'connection_error': 'Connection error. Please check your internet connection.'
     
  };

  // Constructor
  AppLanguage() {
    _translations = Map.from(_defaultStrings);
  }

  // Initialize app language from shared preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language_code') ?? 'en';

    // If not English, load translations
    if (_currentLanguage != 'en') {
      await translateStrings(_currentLanguage);
    }

    notifyListeners();
  }

  // Translate a single text
  Future<String> translate(String text, String targetLanguage) async {
    if (targetLanguage == 'en') return text;

    try {
      final translation = await _translator.translate(text, to: targetLanguage);
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  // Translate all strings to target language
  Future<void> translateStrings(String targetLanguage) async {
    if (targetLanguage == 'en') {
      _translations = Map.from(_defaultStrings);
      return;
    }

    try {
      Map<String, String> newTranslations = {};

      // Translate each string
      for (var entry in _defaultStrings.entries) {
        final translation = await _translator.translate(
          entry.value,
          to: targetLanguage,
        );
        newTranslations[entry.key] = translation.text;
      }

      _translations = newTranslations;
    } catch (e) {
      print('Translation error: $e');
      // Fallback to English if translation fails
      _translations = Map.from(_defaultStrings);
    }
  }

  // Change app language
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;

    _currentLanguage = languageCode;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);

    // Update translations
    await translateStrings(languageCode);

    notifyListeners();
  }

  // Get a translated string
  String get(String key) {
    return _translations[key] ?? _defaultStrings[key] ?? key;
  }
}
