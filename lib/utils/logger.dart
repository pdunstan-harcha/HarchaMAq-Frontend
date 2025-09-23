import 'package:logger/logger.dart';

/// Utilidad para logging seguro que maneja valores null
class SafeLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Número de líneas del stack trace
      errorMethodCount: 8, // Número de líneas para errores
      lineLength: 120, // Longitud de línea
      colors: true, // Colores en consola
      printEmojis: true, // Emojis para diferentes niveles
      dateTimeFormat: DateTimeFormat.none, // Sin timestamp para evitar deprecation
    ),
  );

  static void log(String message, [dynamic value]) {
    if (value != null) {
      _logger.i('$message: ${value.toString()}');
    } else {
      _logger.i('$message: null');
    }
  }

  static void error(String message, [dynamic error]) {
    if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.e('$message: unknown error');
    }
  }

  static void info(String message) {
    _logger.i(message);
  }

  static void debug(String message, [dynamic data]) {
    if (data != null) {
      _logger.d('$message: ${data.toString()}');
    } else {
      _logger.d(message);
    }
  }

  static void warning(String message, [dynamic data]) {
    if (data != null) {
      _logger.w('$message: ${data.toString()}');
    } else {
      _logger.w(message);
    }
  }

  static void verbose(String message, [dynamic data]) {
    if (data != null) {
      _logger.t('$message: ${data.toString()}');
    } else {
      _logger.t(message);
    }
  }
}
