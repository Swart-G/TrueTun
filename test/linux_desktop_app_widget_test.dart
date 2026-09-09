import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/application/app_state.dart';
import 'package:truetun/src/linux_desktop_app.dart';

void main() {
  testWidgets('Linux shell survives routing and profile dialog transitions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith((ref) => AppController()),
        ],
        child: const TrueTunLinuxApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.alt_route).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rule'));
    await tester.pumpAndSettle();
    expect(find.text('Add routing rule'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.memory_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Process rule'));
    await tester.pumpAndSettle();
    expect(find.text('Add process rule'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.dns_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import proxy link / config'));
    await tester.pumpAndSettle();
    expect(find.text('Import proxy'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
