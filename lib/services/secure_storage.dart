import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _keyUserData, value: jsonString);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _storage.read(key: _keyUserData);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Limpiar solo tokens (mantener otros datos si existen)
  static Future<void> clearTokens() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  // Verificar si hay sesión guardada
  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Métodos auxiliares para datos específicos del usuario
  static Future<int?> getUserId() async {
    final userData = await getUserData();
    return userData?['pkUsuario'] as int?;
  }

  static Future<String?> getUserName() async {
    final userData = await getUserData();
    return userData?['NOMBREUSUARIO'] as String?;
  }

  static Future<String?> getUsername() async {
    final userData = await getUserData();
    return userData?['USUARIO'] as String?;
  }

  static Future<String?> getUserRole() async {
    final userData = await getUserData();
    return userData?['ROL'] as String?;
  }
}
