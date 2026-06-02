import 'dart:async';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:personal_haven/core/constants/api_config.dart';
import 'package:personal_haven/data/data_sources/remote/models/token_pair.dart';
import 'package:personal_haven/data/data_sources/remote/models/token_storage.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._init();
  ApiClient._init();

  final http.Client _client = http.Client();

  /// Make authenticated request
  Future<http.Response> request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final requestHeaders = {...ApiConfig.defaultHeaders, ...?headers};

      // Add authentication token if required
      if (requiresAuth) {
        final tokens = await TokenStorage.getTokens();
        if (tokens == null) {
          throw Exception('No authentication tokens found');
        }

        // Refresh token if needed
        if (tokens.needsRefresh) {
          await _refreshTokens(tokens.refreshToken);
          final newTokens = await TokenStorage.getTokens();
          if (newTokens != null) {
            requestHeaders['Authorization'] = 'Bearer ${newTokens.accessToken}';
          }
        } else {
          requestHeaders['Authorization'] = 'Bearer ${tokens.accessToken}';
        }
      }

      http.Response response;
      final encodedBody = body != null ? jsonEncode(body) : null;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(url, headers: requestHeaders)
              .timeout(ApiConfig.connectionTimeout);
          break;
        case 'POST':
          response = await _client.post(url, headers: requestHeaders, body: encodedBody)
              .timeout(ApiConfig.connectionTimeout);
          break;
        case 'PUT':
          response = await _client.put(url, headers: requestHeaders, body: encodedBody)
              .timeout(ApiConfig.connectionTimeout);
          break;
        case 'DELETE':
          response = await _client.delete(url, headers: requestHeaders)
              .timeout(ApiConfig.connectionTimeout);
          break;
        case 'PATCH':
          response = await _client.patch(url, headers: requestHeaders, body: encodedBody)
              .timeout(ApiConfig.connectionTimeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Handle 401 Unauthorized - token expired
      if (response.statusCode == 401 && requiresAuth) {
        final tokens = await TokenStorage.getTokens();
        if (tokens != null) {
          final refreshed = await _refreshTokens(tokens.refreshToken);
          if (refreshed) {
            // Retry the request with new token
            return request(
              method: method,
              endpoint: endpoint,
              body: body,
              headers: headers,
              requiresAuth: requiresAuth,
            );
          }
        }
      }

      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  /// Refresh access token
  Future<bool> _refreshTokens(String refreshToken) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authEndpoint}/refresh'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = TokenPair.fromJson(data['data']);
        await TokenStorage.saveTokens(tokens);
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh failed: $e');
      return false;
    }
  }

  /// GET request
  Future<http.Response> get(String endpoint, {bool requiresAuth = true}) {
    return request(method: 'GET', endpoint: endpoint, requiresAuth: requiresAuth);
  }

  /// POST request
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return request(method: 'POST', endpoint: endpoint, body: body, requiresAuth: requiresAuth);
  }

  /// PUT request
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return request(method: 'PUT', endpoint: endpoint, body: body, requiresAuth: requiresAuth);
  }

  /// DELETE request
  Future<http.Response> delete(String endpoint, {bool requiresAuth = true}) {
    return request(method: 'DELETE', endpoint: endpoint, requiresAuth: requiresAuth);
  }

  /// PATCH request
  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return request(method: 'PATCH', endpoint: endpoint, body: body, requiresAuth: requiresAuth);
  }
}
