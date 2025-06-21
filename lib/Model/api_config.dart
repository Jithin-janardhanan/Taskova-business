

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      print('Warning: BASE_URL not found in .env file, using fallback URL');
      return 'http://default-fallback-url.com';
    }
    // Ensure URL doesn't have trailing slash to avoid double slashes
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // Authentication endpoints
  static String get loginUrl => '$baseUrl/api/login/';
  static String get registerUrl => '$baseUrl/api/register/';
  static String get logoutUrl => '$baseUrl/api/logout/';
  static String get googleUrl => '$baseUrl/social_auth/google-login/';

  // Password management endpoints
  static String get forgotPasswordUrl => '$baseUrl/api/forgot-password/';
  static String get resetPasswordUrl => '$baseUrl/api/reset-password/';

  // OTP endpoints
  static String get verifyOtpUrl => '$baseUrl/api/verify-otp/';
  static String get resendOtpUrl => '$baseUrl/api/resend-otp/';

  // Profile endpoints
  static String get driverProfileUrl => '$baseUrl/api/driver-profile/';
  static String get driverDocumentUrl => '$baseUrl/api/driver-documents/';
  static String get shopkeeperProfileUrl => '$baseUrl/api/shopkeeper/profile/';
  static String get profileStatusUrl => '$baseUrl/api/profile-status/';

  // Business endpoints
  static String get businesses =>
      '$baseUrl/api/shopkeeper/businesses/'; // to choose fetch (it will fetch all the business in one profile)
  static String get jobposts => '$baseUrl/api/job-posts/create/';
  static String get regiserBusiness => '$baseUrl/api/shopkeeper/businesses/';

  static String get fulldriverlist => '$baseUrl/api/drivers/';
}
