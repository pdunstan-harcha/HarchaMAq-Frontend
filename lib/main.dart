import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:harcha_maquinaria/utils/logger.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/connectivity_manager.dart';
import 'services/sync_service.dart';
import 'services/analytics_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Capturar errores de Flutter
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    SafeLogger.error('Flutter Error', errorDetails.exception);
  };

  // 🔥 Capturar errores asíncronos
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runZonedGuarded(() async {
    try {
      // Inicializar Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      SafeLogger.info('Firebase inicializado');

      // 🔥 Inicializar Analytics
      final analyticsService = AnalyticsService();
      await analyticsService.initialize();

      // Inicializar AuthProvider
      final authProvider = AuthProvider();
      await authProvider.initialize();

      // Otros servicios
      final connectivityManager = ConnectivityManager();
      final syncService = SyncService();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: connectivityManager),
            Provider.value(value: syncService),
            Provider.value(value: analyticsService), // 🔥 Agregar
          ],
          child: const HarchaApp(),
        ),
      );
    } catch (e, stack) {
      SafeLogger.error('Error fatal', e);
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
    }
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class HarchaApp extends StatelessWidget {
  const HarchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harcha Maquinaria',
      theme: harchaTheme, // Usar el tema personalizado
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          SafeLogger.debug(
              'Consumer rebuild - isAuthenticated: ${authProvider.isAuthenticated}, user: ${authProvider.user != null}');
          // Mientras verifica autenticación, muestra splash
          if (authProvider.isLoading) {
            return const SplashScreen();
          }

          // Si está autenticado y tiene datos de usuario, va a dashboard
          if (authProvider.isAuthenticated && authProvider.user != null) {
            SafeLogger.info(
                'Navegando a DashboardScreen con usuario: ${authProvider.user}');
            return DashboardScreen(usuario: authProvider.user!);
          } else {
            SafeLogger.info('Mostrando Login');
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) {
          // Para las rutas nombradas, también necesitas pasar el usuario
          return Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.user != null) {
                return DashboardScreen(usuario: authProvider.user!);
              } else {
                return const LoginScreen();
              }
            },
          );
        },
      },
    );
  }
}

// Colores oficiales de Harcha Constructora
const Color harchaBlue = Color(0xFF0066CC); // Azul del logo
const Color harchaGray = Color(0xFF666666); // Gris del logo
const Color harchaLightBlue = Color(0xFF3399FF); // Azul claro para acentos

final ThemeData harchaTheme = ThemeData(
  primaryColor: harchaBlue,
  primaryColorLight: harchaLightBlue,
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
  appBarTheme: const AppBarTheme(
    backgroundColor: harchaBlue,
    foregroundColor: Colors.white,
    elevation: 2,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: harchaBlue,
    secondary: harchaLightBlue,
    surface: const Color(0xFFF8F9FA),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    error: Colors.red,
  ),
  // cardTheme configurado por defecto
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: harchaBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF009FE3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    labelStyle: const TextStyle(color: Color(0xFF003366)),
    iconColor: const Color(0xFF009FE3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  drawerTheme:
      const DrawerThemeData(backgroundColor: Colors.white, elevation: 4),
  listTileTheme: ListTileThemeData(
    iconColor: const Color(0xFF009FE3),
    textColor: const Color(0xFF222222),
    selectedTileColor: const Color(0xFF009FE3).withOpacity(0.1),
    selectedColor: const Color(0xFF003366),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFFD600),
    foregroundColor: Color(0xFF003366),
    elevation: 4,
  ),
);
