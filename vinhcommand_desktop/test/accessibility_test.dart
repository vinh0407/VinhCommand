import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/main.dart';

void main() {
  testWidgets('keyboard palette and settings work at 200 percent text on narrow window', (tester) async {
    tester.view.physicalSize = const Size(700, 1100);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ProviderScope(child: VinhCommandApp()));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Go to a page'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Accessibility'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('settings controls have labels and a reviewable rendered preview', (tester) async {
    await tester.runAsync(() async {
      final font = File(r'C:\Windows\Fonts\consola.ttf');
      if (await font.exists()) {
        final data = ByteData.sublistView(await font.readAsBytes());
        for(final family in ['Inter', 'JetBrainsMono', 'Roboto', 'Ahem', 'Consolas', 'Segoe UI']) {
          await (FontLoader(family)..addFont(Future.value(data))).load();
        }
      }
      final icons = File(r'C:\src\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf');
      if (await icons.exists()) await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(await icons.readAsBytes())))).load();
    });
    tester.view.physicalSize = const Size(1300, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(RepaintBoundary(key: key, child: const ProviderScope(child: VinhCommandApp())));
    await tester.pumpAndSettle();
    final dashboardBoundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final preview = await dashboardBoundary.toImage();
      final png = await preview.toByteData(format: ui.ImageByteFormat.png);
      await File('retro-dashboard-preview.png').writeAsBytes(png!.buffer.asUint8List());
      preview.dispose();
    });
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('High contrast'), findsWidgets);
    expect(find.bySemanticsLabel('Reduce motion'), findsWidgets);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('settings-preview.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });
}




