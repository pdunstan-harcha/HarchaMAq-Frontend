import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:harcha_maquinaria/services/secure_storage.dart';
import '../config.dart';
import '../utils/logger.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final String _baseUrl = AppConfig.baseUrl;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Obtiene headers con token de autorización
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await SecureStorage.getToken();
    return {..._headers, if (token != null) 'Authorization': 'Bearer $token'};
  }

  // GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final baseHeaders = await _getAuthHeaders();

      final headers = {
        ...baseHeaders,
        if (extraHeaders != null) ...extraHeaders,
      };

      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception(
          'Error de conexión: No se pudo conectar al servidor. Verifique su conexión de red.',
        );
      }
      rethrow;
    }
  } // POST request

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _getAuthHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // PUT request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _getAuthHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  // Maneja las respuestas HTTP
  dynamic _handleResponse(http.Response response) async {
    final statusCode = response.statusCode;
    if (response.headers['content-type']?.contains('text/html') == true) {
      if (statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Error $statusCode: ${response.body}');
      }
    }
    try {
      // Verificar si la respuesta está vacía
      if (response.body.isEmpty) {
        throw Exception('Respuesta vacía del servidor');
      }

      final responseBody = jsonDecode(response.body);

      if (statusCode == 401) {
        // Token expirado, intentar refrescar
        final refreshed = await _tryRefreshToken();
        if (!refreshed) {
          throw Exception(
            'Sesión expirada. Por favor, inicie sesión nuevamente.',
          );
        }
        throw Exception('Token refreshed, retry request');
      }

      if (statusCode >= 400) {
        throw Exception(responseBody['message'] ?? 'Error en la petición');
      }

      return responseBody;
    } catch (e) {
      if (e.toString().contains('Token refreshed')) {
        rethrow;
      }

      // Si no se puede parsear JSON, devolver respuesta como texto
      if (statusCode >= 400) {
        throw Exception('Error $statusCode: ${response.body}');
      }

      // Si el status es OK pero no se puede parsear, es un problema de formato
      if (statusCode >= 200 && statusCode < 300) {
        throw Exception('Respuesta del servidor en formato incorrecto: $e');
      }

      return response.body;
    }
  }

  // Intenta refrescar el token
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: _headers,
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await SecureStorage.saveToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await SecureStorage.saveRefreshToken(data['refresh_token']);
        }
        return true;
      }
    } catch (e) {
      SafeLogger.error('Error refreshing token', e);
    }

    // Si falló el refresh, limpiar tokens
    await SecureStorage.clearAll();
    return false;
  }
}
