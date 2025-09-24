import 'utils/logger.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // URLs para diferentes entornos
  static const String devUrl = 'http://localhost:5000';
  static const String androidEmulatorUrl = 'http://10.0.2.2:5000'; 
  static const String iosSimulatorUrl = 'http://localhost:5000'; 
  static const String prodUrl = 'https://harchaback-production.up.railway.app';

  // Lee BASE_URL desde --dart-define
  static const String _envBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: '');

  // Método para obtener la URL apropiada según el entorno
  static String getApiUrl() {
    String apiUrl;

    // Si se especifica BASE_URL en --dart-define, usarla
    if (_envBaseUrl.isNotEmpty) {
      apiUrl = _envBaseUrl;
      SafeLogger.info('🌐 Using BASE_URL from dart-define: $apiUrl');
    }
    // Si está en modo debug (desarrollo local), usar URL local
    else if (kDebugMode) {
      apiUrl = devUrl;
      SafeLogger.info('🔧 Development mode - Using local URL: $apiUrl');
    }
    // Si está en modo release (producción), usar Railway
    else {
      apiUrl = prodUrl;
      SafeLogger.info('🚀 Production mode - Using Railway URL: $apiUrl');
    }

    return apiUrl;
  }

  // Para compatibilidad con código existente
  static String get baseUrl => getApiUrl();
}
