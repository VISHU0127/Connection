import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConstants {
  // ── API Environment Base URLs ──────────────────────────────

  // Android Emulator → host machine
  static const String androidEmulatorBaseUrl =
      'http://10.0.2.2:8000';

  // iOS Simulator / macOS Desktop
  static const String localBaseUrl =
      'http://127.0.0.1:8000';

  // Physical Device → replace with your Mac's LAN IP
  static const String physicalDeviceBaseUrl =
      'http://192.168.1.100:8000';

  // Production
  static const String productionBaseUrl =
      'https://api.yourdomain.com';

  /// Automatically choose the correct backend for the platform.
  static String get baseUrl {
    if (kIsWeb) {
      return localBaseUrl;
    }

    if (Platform.isAndroid) {
      return androidEmulatorBaseUrl;
    }

    // macOS, iOS simulator, etc.
    return localBaseUrl;
  }

  static const Duration connectTimeout =
      Duration(seconds: 15);

  static const Duration receiveTimeout =
      Duration(seconds: 15);

  // ── Auth Storage Keys ──────────────────────────────────────

  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // ── Pagination ──────────────────────────────────────────────

  static const int pageSize = 20;
}