// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  bool _isInitialized = false;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Inicializa Firebase Analytics y Crashlytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;

      // Habilitar recolección de crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // En desarrollo, deshabilitar analytics automático
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);

      _isInitialized = true;
      SafeLogger.info('Firebase Analytics y Crashlytics inicializados');
    } catch (e) {
      SafeLogger.error('Error al inicializar Analytics', e);
    }
  }

  // ==================== EVENTOS DE AUTENTICACIÓN ====================

  /// Usuario inicia sesión
  Future<void> logLogin(String userId, String userName, String method) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logLogin(loginMethod: method);
      await _analytics.setUserId(id: userId);
      await _analytics.setUserProperty(name: 'user_name', value: userName);

      await _crashlytics.setUserIdentifier(userId);
      await _crashlytics.setCustomKey('user_name', userName);

      SafeLogger.info('Analytics: Login registrado - $userName');
    } catch (e) {
      SafeLogger.error('Error al registrar login', e);
    }
  }

  /// Usuario cierra sesión
  Future<void> logLogout(String userId) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'logout',
        parameters: {'user_id': userId},
      );
      SafeLogger.info('Analytics: Logout registrado');
    } catch (e) {
      SafeLogger.error('Error al registrar logout', e);
    }
  }

  // ==================== EVENTOS DE RECARGA DE COMBUSTIBLE ====================

  /// Registro de recarga de combustible
  Future<void> logRecargaCombustible({
    required int maquinaId,
    required String maquinaNombre,
    required double litros,
    required String obraNombre,
    required String clienteNombre,
    required bool isOffline,
  }) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'recarga_combustible',
        parameters: {
          'maquina_id': maquinaId,
          'maquina_nombre': maquinaNombre,
          'litros': litros,
          'obra': obraNombre,
          'cliente': clienteNombre,
          'is_offline': isOffline,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Métricas personalizadas
      if (isOffline) {
        await _analytics.logEvent(name: 'offline_operation_recarga');
      }

      SafeLogger.info('Analytics: Recarga registrada - $maquinaNombre');
    } catch (e) {
      SafeLogger.error('Error al registrar recarga en analytics', e);
    }
  }

  /// Sincronización exitosa de recarga
  Future<void> logRecargaSincronizada(String uuid, int attempts) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'recarga_sincronizada',
        parameters: {
          'uuid': uuid,
          'sync_attempts': attempts,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      SafeLogger.error('Error al registrar sincronización', e);
    }
  }

  // ==================== EVENTOS DE REPORTES ====================

  /// Registro de reporte de contrato
  Future<void> logReporteContrato({
    required int maquinaId,
    required String maquinaNombre,
    required int contratoId,
    required String contratoNombre,
    required double horasTrabajadas,
    required double kilometros,
    required bool isOffline,
  }) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'reporte_contrato',
        parameters: {
          'maquina_id': maquinaId,
          'maquina_nombre': maquinaNombre,
          'contrato_id': contratoId,
          'contrato_nombre': contratoNombre,
          'horas_trabajadas': horasTrabajadas,
          'kilometros': kilometros,
          'is_offline': isOffline,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (isOffline) {
        await _analytics.logEvent(name: 'offline_operation_reporte');
      }

      SafeLogger.info('Analytics: Reporte registrado - $contratoNombre');
    } catch (e) {
      SafeLogger.error('Error al registrar reporte en analytics', e);
    }
  }

  /// Sincronización exitosa de reporte
  Future<void> logReporteSincronizado(String uuid, int attempts) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'reporte_sincronizado',
        parameters: {
          'uuid': uuid,
          'sync_attempts': attempts,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      SafeLogger.error('Error al registrar sincronización', e);
    }
  }

  // ==================== EVENTOS DE CONECTIVIDAD ====================

  /// Cambio de conectividad
  Future<void> logConnectivityChange(bool isOnline) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'connectivity_change',
        parameters: {
          'is_online': isOnline,
          'status': isOnline ? 'online' : 'offline',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      SafeLogger.info(
          'Analytics: Conectividad - ${isOnline ? "Online" : "Offline"}');
    } catch (e) {
      SafeLogger.error('Error al registrar cambio de conectividad', e);
    }
  }

  // ==================== EVENTOS DE SINCRONIZACIÓN ====================

  /// Inicio de sincronización
  Future<void> logSyncStarted(int pendingCount) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'sync_started',
        parameters: {
          'pending_count': pendingCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      SafeLogger.error('Error al registrar inicio de sync', e);
    }
  }

  /// Sincronización completada
  Future<void> logSyncCompleted({
    required int totalSynced,
    required int recargasSynced,
    required int reportesSynced,
    required int failed,
    required Duration duration,
  }) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'sync_completed',
        parameters: {
          'total_synced': totalSynced,
          'recargas_synced': recargasSynced,
          'reportes_synced': reportesSynced,
          'failed': failed,
          'duration_seconds': duration.inSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      SafeLogger.info('Analytics: Sync completado - $totalSynced registros');
    } catch (e) {
      SafeLogger.error('Error al registrar sync completado', e);
    }
  }

  // ==================== EVENTOS DE CACHÉ ====================

  /// Descarga de caché
  Future<void> logCacheDownload({
    required int maquinasCount,
    required int obrasCount,
    required int clientesCount,
    required int contratosCount,
    required Duration duration,
  }) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'cache_download',
        parameters: {
          'maquinas': maquinasCount,
          'obras': obrasCount,
          'clientes': clientesCount,
          'contratos': contratosCount,
          'total_items':
              maquinasCount + obrasCount + clientesCount + contratosCount,
          'duration_seconds': duration.inSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      SafeLogger.info(
          'Analytics: Caché descargado - ${maquinasCount + obrasCount + clientesCount + contratosCount} items');
    } catch (e) {
      SafeLogger.error('Error al registrar descarga de caché', e);
    }
  }

  // ==================== EVENTOS DE NAVEGACIÓN ====================

  /// Navegación entre pantallas
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      SafeLogger.debug('Analytics: Screen view - $screenName');
    } catch (e) {
      SafeLogger.error('Error al registrar screen view', e);
    }
  }

  // ==================== EVENTOS DE ERRORES ====================

  /// Error genérico
  Future<void> logError(String errorType, String message,
      {StackTrace? stackTrace}) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Registrar en Crashlytics si hay stack trace
      if (stackTrace != null) {
        await _crashlytics.recordError(
          Exception(message),
          stackTrace,
          reason: errorType,
          fatal: false,
        );
      }
    } catch (e) {
      SafeLogger.error('Error al registrar error en analytics', e);
    }
  }

  /// Error de API
  Future<void> logApiError(
      String endpoint, int statusCode, String message) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'api_error',
        parameters: {
          'endpoint': endpoint,
          'status_code': statusCode,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      SafeLogger.error('Error al registrar error de API', e);
    }
  }

  // ==================== MÉTRICAS DE RENDIMIENTO ====================

  /// Tiempo de carga de pantalla
  Future<void> logScreenLoadTime(String screenName, Duration loadTime) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: 'screen_load_time',
        parameters: {
          'screen_name': screenName,
          'load_time_ms': loadTime.inMilliseconds,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      SafeLogger.error('Error al registrar tiempo de carga', e);
    }
  }

  // ==================== EVENTOS PERSONALIZADOS ====================

  /// Evento personalizado genérico
  Future<void> logCustomEvent(
      String eventName, Map<String, dynamic> parameters) async {
    if (!_isInitialized) return;

    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      SafeLogger.debug('Analytics: Evento personalizado - $eventName');
    } catch (e) {
      SafeLogger.error('Error al registrar evento personalizado', e);
    }
  }

  // ==================== CRASHLYTICS ====================

  /// Registrar crash fatal
  Future<void> recordFatalError(
      dynamic error, StackTrace stackTrace, String reason) async {
    if (!_isInitialized) return;

    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: true,
      );
      SafeLogger.error('Crashlytics: Error fatal registrado', error);
    } catch (e) {
      SafeLogger.error('Error al registrar en Crashlytics', e);
    }
  }

  /// Agregar log personalizado para debugging
  void log(String message) {
    if (!_isInitialized) return;
    _crashlytics.log(message);
  }

  /// Establecer clave personalizada
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isInitialized) return;

    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      SafeLogger.error('Error al establecer custom key', e);
    }
  }

  // ==================== UTILIDADES ====================

  /// Limpiar usuario actual
  Future<void> clearUser() async {
    if (!_isInitialized) return;

    try {
      await _analytics.setUserId(id: null);
      await _crashlytics.setUserIdentifier('');
      SafeLogger.info('Analytics: Usuario limpiado');
    } catch (e) {
      SafeLogger.error('Error al limpiar usuario', e);
    }
  }

  /// Establecer propiedad de usuario
  Future<void> setUserProperty(String name, String value) async {
    if (!_isInitialized) return;

    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      SafeLogger.error('Error al establecer user property', e);
    }
  }

  /// Verificar si está inicializado
  bool get isInitialized => _isInitialized;
}
