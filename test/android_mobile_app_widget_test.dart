import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truetun/src/android_mobile_app_v2.dart';
import 'package:truetun/src/application/app_state.dart';

void main() {
  testWidgets('Android shell survives dialog transitions and teardown', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith((ref) => AppController()),
        ],
        child: const TrueTunAndroidApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.dns_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import proxy link / config'));
    await tester.pumpAndSettle();
    expect(find.text('Import proxy'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.alt_route));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add rule'));
    await tester.pumpAndSettle();
    expect(find.text('Add routing rule'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
