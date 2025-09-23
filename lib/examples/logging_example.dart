import '../utils/logger.dart';

/// Ejemplo de uso del sistema de logging
class LoggingExample {
  
  static void demonstrateLogging() {
    // Información general
    SafeLogger.info('Aplicación iniciada correctamente');
    
    // Debug con datos
    SafeLogger.debug('Usuario logueado', {'id': 123, 'nombre': 'Juan'});
    
    // Advertencia
    SafeLogger.warning('Conexión lenta detectada');
    
    // Error con excepción
    try {
      throw Exception('Error de prueba');
    } catch (e) {
      SafeLogger.error('Error al procesar datos', e);
    }
    
    // Log genérico
    SafeLogger.log('Operación completada', 'resultado exitoso');
    
    // Verbose para información muy detallada
    SafeLogger.verbose('Detalle técnico', {'memoria': '4GB', 'cpu': '80%'});
  }
}