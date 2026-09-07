// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truetun/src/app.dart';
import 'package:truetun/src/application/app_state.dart';

void main() {
  testWidgets('shows the TrueTun shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith((ref) => AppController()),
        ],
        child: const TrueTunApp(),
      ),
    );
    expect(find.text('TrueTun'), findsWidgets);
    expect(find.text('Proxy client foundation for Android and Linux'),
        findsNothing);
    expect(find.text('NO PROFILE'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
    expect(find.text('PING'), findsOneWidget);
    expect(find.text('Traffic'), findsOneWidget);
    expect(find.text('Core'), findsNothing);
  });

  testWidgets('profile groups can be collapsed and expanded', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController();
    controller.importVless(
      'vless://00000000-0000-4000-8000-000000000000@example.com:443'
      '?security=tls&type=ws#Saved profile',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith((ref) => controller),
        ],
        child: const TrueTunApp(),
      ),
    );

    await tester.tap(find.text('Profiles'));
    await tester.pumpAndSettle();
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('Saved profile'), findsOneWidget);

    await tester.tap(find.byTooltip('Collapse group'));
    await tester.pumpAndSettle();
    expect(find.text('Saved profile'), findsNothing);
    expect(find.byTooltip('Expand group'), findsOneWidget);

    await tester.tap(find.byTooltip('Expand group'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Test latency'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit connection'));
    await tester.pumpAndSettle();
    expect(find.text('Edit connection'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Group actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit group'));
    await tester.pumpAndSettle();
    expect(find.text('Automatic updates'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
