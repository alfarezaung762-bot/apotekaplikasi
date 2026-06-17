import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(ApiConfig.fullUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(ApiConfig.fullUrl(endpoint));
      final response = await _client.post(uri, headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(ApiConfig.fullUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client.patch(uri, headers: _headers, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(ApiConfig.fullUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client.delete(uri, headers: _headers).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(ApiConfig.fullUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client.put(uri, headers: _headers, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Koneksi gagal: $e'};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {'success': false, 'error': 'Server error (non-JSON response)'};
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      }
      return {'success': false, 'error': json['error'] ?? 'Request failed', ...json};
    } catch (e) {
      return {'success': false, 'error': 'Parse error: $e'};
    }
  }
}
