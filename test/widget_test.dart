// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harcha_maquinaria/main.dart';

void main() {
  testWidgets('HarchaApp basic functionality test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HarchaApp());

    // Wait for the initial frame to be rendered
    await tester.pump();

    // Verify that the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that the login screen is displayed
    expect(find.text('Login Harcha'), findsOneWidget);

    // Verify that login form elements are present
    expect(
      find.byType(TextField),
      findsNWidgets(2),
    ); // Usuario and Contraseña fields
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    // Verify that the app has the correct structure
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('HarchaApp theme test', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const HarchaApp());

    // Verify that the app uses the correct theme
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'Harcha Maquinaria');
  });
}
