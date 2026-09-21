import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/main.dart';

void main() {
  testWidgets('navigation reaches settings and preserves system text scaling', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ProviderScope(child: VinhCommandApp()));
    await tester.pump();
    final text = tester.element(find.text('AI Agent Command Center'));
    expect(MediaQuery.textScalerOf(text).scale(10), 15);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Accessibility'), findsOneWidget);
    await tester.tap(find.text('High contrast'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}


