import 'utils/logger.dart';

class AppConfig {
  // Lee BASE_URL desde --dart-define, con valor por defecto
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://harchaback-production.up.railway.app', // URL de producción por defecto
  );

  // URLs para diferentes entornos
  static const String devUrl = 'http://127.0.0.1:5000';
  static const String androidEmulatorUrl =
      'http://10.0.2.2:5000'; // Para emulador Android
  static const String iosSimulatorUrl =
      'http://localhost:5000'; // Para iOS simulator
  static const String prodUrl =
      'https://harchaback-production.up.railway.app'; // URL de producción en Railway

  // Método para obtener la URL apropiada según el entorno
  static String getApiUrl() {
    try {
      SafeLogger.info('🌐 Using API URL: $baseUrl');
    } catch (e) {
      SafeLogger.error('Error in config print', e);
    }
    return baseUrl;
  }
}
