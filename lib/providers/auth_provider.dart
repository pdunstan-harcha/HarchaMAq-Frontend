import 'package:flutter/material.dart';
import '../services/secure_storage.dart';
import '../services/database_helper.dart';
import '../services/connectivity_manager.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  final ConnectivityManager _connectivityManager = ConnectivityManager();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final SyncService _syncService = SyncService();

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get userRole => _user?['ROL'];
  int? get userId => _user?['pkUsuario'];
  bool get isOnline => _connectivityManager.isOnline;

  // Verifica si el usuario está autenticado al iniciar la app
  Future<void> initialize() async {
    try {
      // Inicializar servicios
      await _connectivityManager.initialize();
      await _syncService.initialize();

      // Verificar si hay sesión guardada
      // Verificar si hay sesión guardada
      final hasSession = await SecureStorage.hasSession();
      if (hasSession) {
        final userData = await SecureStorage.getUserData();
        if (userData != null && userData.isNotEmpty) {
          _user = userData;
          _isAuthenticated = true;
          SafeLogger.info('Sesión restaurada: ${userData['NOMBREUSUARIO']}');
          notifyListeners();

          // Pre-cargar datos en caché si hay conexión
          if (_connectivityManager.isOnline) {
            _preloadCachedData();
          }
        } else {
          // Token existe pero no hay datos de usuario, limpiar
          SafeLogger.warning('Token sin datos de usuario, limpiando sesión');
          await SecureStorage.clearAll();
        }
      }
    } catch (e) {
      SafeLogger.error('Error al inicializar AuthProvider', e);
      // En caso de error, limpiar sesión corrupta
      await SecureStorage.clearAll();
    }
  }

  /// Pre-carga datos en caché para uso offline
  Future<void> _preloadCachedData() async {
    try {
      SafeLogger.info('Precargando datos en caché...');

      // Cargar datos en paralelo para mejor rendimiento
      await Future.wait([
        _cacheMaquinas(),
        _cacheObras(),
        _cacheClientes(),
        _cacheContratos(),
      ]);

      SafeLogger.info('Datos precargados exitosamente');
    } catch (e) {
      SafeLogger.warning('Error al precargar datos en caché', e);
    }
  }

  Future<void> _cacheMaquinas() async {
    try {
      final maquinas = await DatabaseHelper.obtenerMaquinas();
      if (maquinas.isNotEmpty) {
        await _offlineStorage.cacheMaquinas(maquinas);
        SafeLogger.info('Máquinas cacheadas: ${maquinas.length}');
      }
    } catch (e) {
      SafeLogger.error('Error al cachear máquinas', e);
    }
  }

  Future<void> _cacheObras() async {
    try {
      final obras = await DatabaseHelper.obtenerObras();
      if (obras.isNotEmpty) {
        await _offlineStorage.cacheObras(obras);
        SafeLogger.info('Obras cacheadas: ${obras.length}');
      }
    } catch (e) {
      SafeLogger.error('Error al cachear obras', e);
    }
  }

  Future<void> _cacheClientes() async {
    try {
      final clientes = await DatabaseHelper.obtenerClientes();
      if (clientes.isNotEmpty) {
        await _offlineStorage.cacheClientes(clientes);
        SafeLogger.info('Clientes cacheados: ${clientes.length}');
      }
    } catch (e) {
      SafeLogger.error('Error al cachear clientes', e);
    }
  }

  Future<void> _cacheContratos() async {
    try {
      final contratos = await DatabaseHelper.obtenerContratos();
      if (contratos.isNotEmpty) {
        await _offlineStorage.cacheContratos(contratos);
        SafeLogger.info('Contratos cacheados: ${contratos.length}');
      }
    } catch (e) {
      SafeLogger.error('Error al cachear contratos', e);
    }
  }

  // Login del usuario
  Future<bool> login(String usuario, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await DatabaseHelper.login(usuario, password);

      if (response != null && response['success'] == true) {
        // Validar que existan los datos del usuario
        if (response['user'] == null) {
          SafeLogger.error('Login exitoso pero sin datos de usuario');
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _user = response['user'];
        _isAuthenticated = true;

        // Guardar datos del usuario
        await SecureStorage.saveUserData(_user!);

        SafeLogger.info(
            'Login exitoso: ${_user!['NOMBREUSUARIO'] ?? _user!['USUARIO']}');

        // Pre-cargar datos en caché después del login
        if (_connectivityManager.isOnline) {
          // No usar await para no bloquear la UI
          _preloadCachedData().catchError((error) {
            SafeLogger.warning('Error al precargar caché en background', error);
          });
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      SafeLogger.error('Error en login', e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await DatabaseHelper.logout();
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      SafeLogger.error('Error en logout', e);
    }
  }

  /// Fuerza recarga de caché
  Future<void> refreshCache() async {
    if (!_connectivityManager.isOnline) {
      SafeLogger.warning('No se puede refrescar caché sin conexión');
      return;
    }

    await _preloadCachedData();
  }
}
