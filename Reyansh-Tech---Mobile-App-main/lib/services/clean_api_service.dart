import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// 1. ENVIRONMENT CONFIGURATION & CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

class AppConfig {
  // Android Emulator: 10.0.2.2 maps to the host computer's localhost
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000';
  
  // iOS Simulator or Web: localhost
  static const String iosSimulatorUrl = 'http://localhost:8000';
  
  // Physical Device (Replace with host Wi-Fi local IP)
  static const String physicalDeviceUrl = 'http://192.168.1.100:8000';

  // Select active target environment here
  static String get baseUrl => kIsWeb
      ? iosSimulatorUrl
      : (Platform.isAndroid ? androidEmulatorUrl : iosSimulatorUrl);

  static const Duration timeout = Duration(seconds: 15);
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. DATA MODELS WITH DEFENSIVE JSON DESERIALIZATION
// ─────────────────────────────────────────────────────────────────────────────

class User {
  final String id;
  final String email;
  final String fullName;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? 'User',
      role: json['role']?.toString() ?? 'DRIVER',
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String status;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.status,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: json['year'] is int ? json['year'] as int : int.tryParse(json['year']?.toString() ?? '2024') ?? 2024,
      licensePlate: json['license_plate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class Trip {
  final String id;
  final String startLocation;
  final String endLocation;
  final double distanceKm;
  final String status;

  Trip({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.distanceKm,
    required this.status,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id']?.toString() ?? '',
      startLocation: json['start_location']?.toString() ?? '',
      endLocation: json['end_location']?.toString() ?? '',
      distanceKm: (json['distance_km'] is num) ? (json['distance_km'] as num).toDouble() : 0.0,
      status: json['status']?.toString() ?? 'COMPLETED',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CUSTOM EXCEPTIONS
// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. CLEAN HTTP API CLIENT
// ─────────────────────────────────────────────────────────────────────────────

class CleanApiClient {
  final http.Client _client = http.Client();
  String? _authToken;

  void setAuthToken(String token) => _authToken = token;
  void clearAuthToken() => _authToken = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final url = '${AppConfig.baseUrl}$cleanPath';
    final uri = Uri.parse(url);
    return queryParams != null && queryParams.isNotEmpty
        ? uri.replace(queryParameters: queryParams)
        : uri;
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(path, queryParams);
    try {
      final response = await _client.get(uri, headers: _headers).timeout(AppConfig.timeout);
      return _parseResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach backend server. Check host IP and connection.');
    } on TimeoutException {
      throw ApiException('Request timed out after ${AppConfig.timeout.inSeconds} seconds.');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    try {
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(AppConfig.timeout);
      return _parseResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach backend server. Check host IP and connection.');
    } on TimeoutException {
      throw ApiException('Request timed out after ${AppConfig.timeout.inSeconds} seconds.');
    }
  }

  dynamic _parseResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final errorMessage = decoded is Map && decoded.containsKey('detail')
        ? decoded['detail'].toString()
        : 'HTTP Error ${response.statusCode}';
        
    throw ApiException(errorMessage, statusCode: response.statusCode);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. REPOSITORY / API SERVICES
// ─────────────────────────────────────────────────────────────────────────────

class BackendService {
  final CleanApiClient api = CleanApiClient();

  /// Authenticate driver/user and store JWT token
  Future<AuthResponse> login(String username, String password) async {
    final data = await api.post('/api/v1/auth/login', {
      'username': username,
      'password': password,
    });
    final authRes = AuthResponse.fromJson(data as Map<String, dynamic>);
    api.setAuthToken(authRes.accessToken);
    return authRes;
  }

  /// Fetch vehicles list
  Future<List<Vehicle>> getVehicles() async {
    final data = await api.get('/api/v1/vehicles');
    final items = (data['items'] as List? ?? []);
    return items.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch trips history
  Future<List<Trip>> getTrips() async {
    final data = await api.get('/api/v1/trips');
    final items = (data['items'] as List? ?? []);
    return items.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch current user profile
  Future<User> getMyProfile() async {
    final data = await api.get('/api/v1/users/me');
    return User.fromJson(data as Map<String, dynamic>);
  }
}
