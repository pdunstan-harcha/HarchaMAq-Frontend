import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class ConnectivityManager with ChangeNotifier {
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// Inicializa el monitor de conectividad
  Future<void> initialize() async {
    try {
      // Verificar estado inicial
      await _checkInitialConnection();

      // Escuchar cambios de conectividad
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          SafeLogger.error('Error en monitoreo de conectividad', error);
        },
      );

      SafeLogger.info(
          'ConnectivityManager inicializado - Estado: ${_isOnline ? "Online" : "Offline"}');
    } catch (e) {
      SafeLogger.error('Error al inicializar ConnectivityManager', e);
      _isOnline = false; // Asumir offline en caso de error
    }
  }

  /// Verifica el estado inicial de conectividad
  Future<void> _checkInitialConnection() async {
    try {
      final ConnectivityResult connectivityResult =
          await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResult);
    } catch (e) {
      SafeLogger.error('Error al verificar conectividad inicial', e);
      _isOnline = false;
      notifyListeners();
    }
  }

  /// Actualiza el estado de conexión basado en el resultado
  void _updateConnectionStatus(ConnectivityResult result) {
    final bool wasOnline = _isOnline;

    // Consideramos que estamos online si hay conexión móvil, wifi o ethernet
    _isOnline = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;

    // Solo notificar si el estado cambió
    if (wasOnline != _isOnline) {
      SafeLogger.info(
          'Estado de conectividad cambió: ${_isOnline ? "Online" : "Offline"}');
      notifyListeners();
    }
  }

  /// Fuerza una verificación manual de conectividad
  Future<bool> checkConnectivity() async {
    try {
      final ConnectivityResult connectivityResult =
          await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResult);
      return _isOnline;
    } catch (e) {
      SafeLogger.error('Error al verificar conectividad manualmente', e);
      return false;
    }
  }

  /// Libera recursos
  @override
  void dispose() {
    try {
      _connectivitySubscription?.cancel();
    } catch (e) {
      SafeLogger.error('Error al liberar recursos de ConnectivityManager', e);
    }
    super.dispose();
  }
}
