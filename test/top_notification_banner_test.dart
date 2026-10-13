import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_care/core/utils/top_notification_banner.dart';
import 'package:health_care/models/alert_model.dart';

void main() {
  testWidgets('TopNotificationBanner displays compact top banner and allows background interaction',
      (WidgetTester tester) async {
    bool backgroundButtonPressed = false;
    bool bannerTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigatorKey,
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                backgroundButtonPressed = true;
              },
              child: const Text('Background Action'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Background Action'), findsOneWidget);

    // Trigger banner
    TopNotificationBanner.show(
      title: 'New message',
      message: 'You have received a new consultation message.',
      timestamp: 'Just now',
      onTap: () {
        bannerTapped = true;
      },
    );

    // Advance animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify banner content is visible
    expect(find.text('New message'), findsOneWidget);
    expect(find.text('You have received a new consultation message.'), findsOneWidget);
    expect(find.text('Just now'), findsOneWidget);

    // Verify background button is NOT blocked by modal barrier and can still be tapped
    await tester.tap(find.text('Background Action'));
    await tester.pump();
    expect(backgroundButtonPressed, isTrue);

    // Verify banner itself can be tapped
    await tester.tap(find.text('New message'));
    await tester.pump();
    expect(bannerTapped, isTrue);

    // Verify banner auto-dismisses after duration
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('New message'), findsNothing);
  });

  testWidgets('TopNotificationBanner.showAlert formats alert text to sentence case and handles severity',
      (WidgetTester tester) async {
    final alert = AlertModel(
      id: 'alert-101',
      patientId: 'patient-1',
      patientName: 'Jane Doe',
      type: 'NO_LOG_3_DAYS',
      title: 'NO_LOG_3_DAYS',
      description: 'Patient has not submitted daily logs for 3 consecutive days.',
      severity: 'HIGH',
      status: 'PENDING',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigatorKey,
        home: const Scaffold(
          body: Center(child: Text('Dashboard View')),
        ),
      ),
    );

    TopNotificationBanner.showAlert(null, alert);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Sentence-case human-readable title and description
    expect(find.text('Patient has not logged in'), findsOneWidget);
    expect(find.text('The patient has not logged in for the past 3 days.'), findsOneWidget);

    // Cleanly dismiss banner before next test
    TopNotificationBanner.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('TopNotificationBanner handles multiple incoming notifications cleanly by replacing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigatorKey,
        home: const Scaffold(
          body: Center(child: Text('Home Screen')),
        ),
      ),
    );

    // First notification
    TopNotificationBanner.show(
      title: 'First Notification',
      message: 'Message number 1',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('First Notification'), findsOneWidget);

    // Second notification immediately replaces first
    TopNotificationBanner.show(
      title: 'Second Notification',
      message: 'Message number 2',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('First Notification'), findsNothing);
    expect(find.text('Second Notification'), findsOneWidget);

    // Dismiss
    TopNotificationBanner.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
