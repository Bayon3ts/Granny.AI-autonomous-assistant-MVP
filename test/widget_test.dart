import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:granny_autonoumus/main.dart';
import 'package:granny_autonoumus/screens/onboarding_screen.dart';

void main() {
  testWidgets('App launches with Onboarding screen', (WidgetTester tester) async {
    // Build app with a known start screen
    await tester.pumpWidget(
      const GrannyAiApp(startScreen: OnboardingScreen()),
    );

    // Verify MaterialApp is built
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify onboarding screen is shown
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
