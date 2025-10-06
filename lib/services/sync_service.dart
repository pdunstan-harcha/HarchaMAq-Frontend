import 'dart:async';
import '../services/connectivity_manager.dart';
import '../services/offline_storage_service.dart';
import '../services/database_helper.dart';
import '../utils/logger.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityManager _connectivityManager = ConnectivityManager();
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  bool _isSyncing = false;
  bool _isInitialized = false;

  bool get isSyncing => _isSyncing;

  /// Inicializa el servicio de sincronización
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Escuchar cambios de conectividad usando el patrón Observer
      _connectivityManager.addListener(_onConnectivityChanged);

      // Sincronizar inmediatamente si hay conexión
      if (_connectivityManager.isOnline) {
        _syncPendingData();
      }

      _isInitialized = true;
      SafeLogger.info('SyncService inicializado');
    } catch (e) {
      SafeLogger.error('Error al inicializar SyncService', e);
    }
  }

  /// Maneja cambios de conectividad
  void _onConnectivityChanged() {
    if (_connectivityManager.isOnline && !_isSyncing) {
      SafeLogger.info('Conexión restaurada - iniciando sincronización');
      _syncPendingData();
    }
  }

  /// Sincroniza datos pendientes
  Future<void> _syncPendingData() async {
    if (_isSyncing) {
      SafeLogger.debug('Sincronización ya en progreso, saltando');
      return;
    }

    _isSyncing = true;
    SafeLogger.info('Iniciando sincronización de datos offline');

    try {
      await _syncRecargasCombustible();

      // Limpiar registros antiguos después de sincronizar
      await _offlineStorage.cleanOldSyncedRecords();

      SafeLogger.info('Sincronización completada exitosamente');
    } catch (e) {
      SafeLogger.error('Error durante la sincronización', e);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sincroniza recargas de combustible pendientes
  Future<void> _syncRecargasCombustible() async {
    try {
      final pendingRecargas = await _offlineStorage.getPendingRecargas();

      if (pendingRecargas.isEmpty) {
        SafeLogger.debug('No hay recargas pendientes para sincronizar');
        return;
      }

      SafeLogger.info(
          'Sincronizando ${pendingRecargas.length} recargas pendientes');

      for (final recarga in pendingRecargas) {
        await _syncSingleRecarga(recarga);
      }
    } catch (e) {
      SafeLogger.error('Error al sincronizar recargas', e);
    }
  }

  /// Sincroniza una recarga individual
  Future<void> _syncSingleRecarga(Map<String, dynamic> recarga) async {
    try {
      SafeLogger.debug('Sincronizando recarga: ${recarga['uuid']}');

      // Incrementar contador de intentos
      await _offlineStorage.incrementSyncAttempts(recarga['uuid']);

      // Llamar al método online original del DatabaseHelper
      final result = await DatabaseHelper.registrarRecargaCombustible(
        idMaquina: recarga['id_maquina'],
        usuarioId: recarga['usuario_id'],
        fechahora: recarga['fechahora'],
        litros: recarga['litros'],
        obraId: recarga['obra_id'],
        clienteId: recarga['cliente_id'],
        operadorId: recarga['operador_id'],
        rutOperador: recarga['rut_operador'],
        nombreOperador: recarga['nombre_operador'],
        observaciones: recarga['observaciones'],
        odometro: recarga['odometro'],
        kilometros: recarga['kilometros'],
        patente: recarga['patente'],
      );

      if (result['success'] == true) {
        // Marcar como sincronizado
        await _offlineStorage.markRecargaAsSynced(recarga['uuid']);
        SafeLogger.info(
            'Recarga sincronizada exitosamente: ${recarga['uuid']}');
      } else {
        SafeLogger.warning(
            'Fallo al sincronizar recarga: ${recarga['uuid']} - ${result['message']}');
      }
    } catch (e) {
      SafeLogger.error(
          'Error al sincronizar recarga individual: ${recarga['uuid']}', e);

      // Si hay muchos intentos fallidos, considerar marcar como error permanente
      if (recarga['sync_attempts'] != null && recarga['sync_attempts'] >= 5) {
        SafeLogger.warning(
            'Recarga con demasiados intentos fallidos: ${recarga['uuid']}');
      }
    }
  }

  /// Fuerza una sincronización manual
  Future<bool> forceSyncNow() async {
    if (!_connectivityManager.isOnline) {
      SafeLogger.warning('No se puede forzar sincronización sin conexión');
      return false;
    }

    try {
      await _syncPendingData();
      return true;
    } catch (e) {
      SafeLogger.error('Error en sincronización forzada', e);
      return false;
    }
  }

  /// Obtiene el número de elementos pendientes de sincronización
  Future<int> getPendingCount() async {
    try {
      final pending = await _offlineStorage.getPendingRecargas();
      return pending.length;
    } catch (e) {
      SafeLogger.error('Error al obtener conteo de pendientes', e);
      return 0;
    }
  }

  /// Libera recursos
  void dispose() {
    _connectivityManager.removeListener(_onConnectivityChanged);
    _isInitialized = false;
  }
}
