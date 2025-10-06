import 'package:flutter/material.dart';
import '../services/secure_storage.dart';
import '../services/database_helper.dart';
import '../services/connectivity_manager.dart';
import '../services/sync_service.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  final ConnectivityManager _connectivityManager = ConnectivityManager();
  final SyncService _syncService = SyncService();

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get userRole => _user?['ROL'];
  int? get userId => _user?['pkUsuario'];
  bool get isOnline => _connectivityManager.isOnline;

  // Verifica si el usuario está autenticado al iniciar la app
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Inicializar monitor de conectividad
      await _connectivityManager.initialize();

      // Inicializar servicio de sincronización
      await _syncService.initialize();

      final token = await SecureStorage.getToken();
      if (token != null) {
        _isAuthenticated = true;
      }
    } catch (e) {
      SafeLogger.error('Error checking auth', e);
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login del usuario
  Future<bool> login(String usuario, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await DatabaseHelper.login(usuario, password);

      if (result != null && result['success'] == true) {
        // Guardar toda la información del usuario del backend
        _user = result['user'] ??
            {
              'NOMBREUSUARIO': usuario,
              'pkUsuario': result['user_id'] ?? 1,
              'username': usuario,
            };
        _isAuthenticated = true;
        notifyListeners();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      SafeLogger.error('Login error', e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Logout del usuario
  Future<void> logout() async {
    try {
      await DatabaseHelper.logout();
    } catch (e) {
      SafeLogger.error('Logout error', e);
    }

    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
