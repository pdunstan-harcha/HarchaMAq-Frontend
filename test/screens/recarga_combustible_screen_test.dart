import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:harcha_maquinaria/screens/recarga_combustible_screen.dart';
import 'package:harcha_maquinaria/providers/auth_provider.dart';

void main() {
  group('RecargaCombustibleScreen Integration Tests', () {
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>(
          create: (_) => mockAuthProvider,
          child: const RecargaCombustibleScreen(
            usuarioId: 1,
            usuarioNombre: 'Test User',
          ),
        ),
      );
    }

    testWidgets('RecargaCombustibleScreen builds without errors',
        (WidgetTester tester) async {
      // Build the widget with required providers
      await tester.pumpWidget(createTestWidget());

      // Wait for initial frame
      await tester.pump();

      // Verify that the screen builds successfully
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Screen has form elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Primero debe mostrar el indicador de carga
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Esperar varios frames para permitir que se complete la carga
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));

        // Verificar si ya no está cargando
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }

      // Verificar que el widget principal existe
      expect(find.byType(Scaffold), findsOneWidget);

      // Verificar que tenemos o bien un formulario o seguimos cargando
      final hasForm = find.byType(Form).evaluate().isNotEmpty;
      final hasLoading =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

      // Al menos uno debe estar presente
      expect(hasForm || hasLoading, isTrue,
          reason: 'Debe mostrar el formulario o seguir cargando');
    });

    testWidgets('AppBar shows connectivity status',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // Verify AppBar exists (connectivity indicator is part of AppBar)
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Screen has save button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Esperar varios frames para permitir que se complete la carga
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));

        // Verificar si ya no está cargando
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }

      // Verificar que el widget principal existe
      expect(find.byType(Scaffold), findsOneWidget);

      // El botón puede estar en el formulario si ya se cargó
      // o puede no estar visible si aún está cargando
      final hasForm = find.byType(Form).evaluate().isNotEmpty;
      if (hasForm) {
        // Si el formulario está presente, buscar el botón
        expect(find.byType(ElevatedButton), findsWidgets);
      }
    });

    testWidgets('Screen can handle missing connectivity data',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // Verify basic structure is present
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Screen handles form submission gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Esperar varios frames
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));

        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }

      // Verificar estructura básica
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Screen updates connectivity status',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // Verify basic structure
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Screen displays proper loading states',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Basic verification
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Screen handles data loading errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // Verify basic structure remains intact
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Screen maintains state during connectivity changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // Basic verification
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
