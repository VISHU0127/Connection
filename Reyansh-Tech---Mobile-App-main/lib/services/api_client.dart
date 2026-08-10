import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// Central HTTP client for all API calls.
/// Includes request/response logging interceptor and network exception handling.
class ApiClient {
  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setToken(String token) => _authToken = token;
  void clearToken() => _authToken = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final urlStr = '${AppConstants.baseUrl}$cleanPath';
    final baseUri = Uri.parse(urlStr);
    if (queryParams != null && queryParams.isNotEmpty) {
      return baseUri.replace(queryParameters: queryParams);
    }
    return baseUri;
  }

  void _logRequest(String method, Uri uri, {dynamic body}) {
    if (kDebugMode) {
      debugPrint('┌── [HTTP REQUEST] $method $uri');
      debugPrint('│ Headers: $_headers');
      if (body != null) {
        debugPrint('│ Body: ${jsonEncode(body)}');
      }
      debugPrint('└──');
    }
  }

  void _logResponse(http.Response response, int durationMs) {
    if (kDebugMode) {
      debugPrint('┌── [HTTP RESPONSE] ${response.statusCode} ${response.request?.url} (${durationMs}ms)');
      debugPrint('│ Body: ${response.body}');
      debugPrint('└──');
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = _uri(path, queryParams);
    _logRequest('GET', uri);
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConstants.receiveTimeout);
      stopwatch.stop();
      _logResponse(response, stopwatch.elapsedMilliseconds);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('No internet connection or server unreachable (${e.message})');
    } on TimeoutException {
      throw NetworkException('Request timeout after ${AppConstants.receiveTimeout.inSeconds}s');
    } on FormatException {
      throw NetworkException('Invalid JSON response format received from server');
    }
  }

  Future<dynamic> post(String path, dynamic body) async {
    final uri = _uri(path);
    _logRequest('POST', uri, body: body);
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(AppConstants.receiveTimeout);
      stopwatch.stop();
      _logResponse(response, stopwatch.elapsedMilliseconds);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('No internet connection or server unreachable (${e.message})');
    } on TimeoutException {
      throw NetworkException('Request timeout after ${AppConstants.receiveTimeout.inSeconds}s');
    } on FormatException {
      throw NetworkException('Invalid response format received from server');
    }
  }

  Future<dynamic> patch(String path, dynamic body) async {
    final uri = _uri(path);
    _logRequest('PATCH', uri, body: body);
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .patch(uri, headers: _headers, body: jsonEncode(body))
          .timeout(AppConstants.receiveTimeout);
      stopwatch.stop();
      _logResponse(response, stopwatch.elapsedMilliseconds);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('No internet connection or server unreachable (${e.message})');
    } on TimeoutException {
      throw NetworkException('Request timeout after ${AppConstants.receiveTimeout.inSeconds}s');
    } on FormatException {
      throw NetworkException('Invalid response format received from server');
    }
  }

  Future<dynamic> put(String path, dynamic body) async {
    final uri = _uri(path);
    _logRequest('PUT', uri, body: body);
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(AppConstants.receiveTimeout);
      stopwatch.stop();
      _logResponse(response, stopwatch.elapsedMilliseconds);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('No internet connection or server unreachable (${e.message})');
    } on TimeoutException {
      throw NetworkException('Request timeout after ${AppConstants.receiveTimeout.inSeconds}s');
    } on FormatException {
      throw NetworkException('Invalid response format received from server');
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = _uri(path);
    _logRequest('DELETE', uri);
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(AppConstants.receiveTimeout);
      stopwatch.stop();
      _logResponse(response, stopwatch.elapsedMilliseconds);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('No internet connection or server unreachable (${e.message})');
    } on TimeoutException {
      throw NetworkException('Request timeout after ${AppConstants.receiveTimeout.inSeconds}s');
    } on FormatException {
      throw NetworkException('Invalid response format received from server');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) return null;

    dynamic jsonBody;
    try {
      if (response.body.isNotEmpty) {
        jsonBody = jsonDecode(response.body);
      }
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    // Extract error message from FastAPI structured error or plain detail
    String errorMessage = 'Request failed with status code ${response.statusCode}';
    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody.containsKey('detail')) {
        final detail = jsonBody['detail'];
        if (detail is Map<String, dynamic> && detail.containsKey('error')) {
          errorMessage = detail['error']['message'] as String? ?? errorMessage;
        } else if (detail is String) {
          errorMessage = detail;
        }
      } else if (jsonBody.containsKey('error') && jsonBody['error'] is Map) {
        errorMessage = jsonBody['error']['message'] as String? ?? errorMessage;
      }
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException(errorMessage);
    } else if (response.statusCode == 403) {
      throw ForbiddenException(errorMessage);
    } else if (response.statusCode == 404) {
      throw NotFoundException(errorMessage);
    } else {
      throw ApiException(statusCode: response.statusCode, message: errorMessage);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Unauthorized or session expired']);
  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;
  const ForbiddenException([this.message = 'Forbidden access']);
  @override
  String toString() => 'ForbiddenException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException([this.message = 'Resource not found']);
  @override
  String toString() => 'NotFoundException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

