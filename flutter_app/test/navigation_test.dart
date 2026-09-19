import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/game/fruit_sprites.dart';
import 'package:flutter_app/models/skin_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/game.dart';
import 'package:flutter_app/game/fruit_merge_game.dart';

import 'audio_mock.dart';

Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
    'tutorial once, pause outside/back, restart cancel, background and continue',
    (tester) async {
      mockAudioChannels();
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      SharedPreferences.setMockInitialValues({
        'fruitMergeAdventure.save': jsonEncode({
          'music': false,
          'sfx': false,
          'vibration': false,
        }),
      });
      await tester.runAsync(() => FruitSprites.use(kDefaultSkinId));
      await tester.pumpWidget(const FruitMergeApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Main Baru'));
      await tester.tap(find.text('Main Baru'));
      await frames(tester);
      expect(find.textContaining('1/3'), findsOneWidget);
      await tester.tap(find.text('Berikutnya'));
      await frames(tester);
      expect(find.textContaining('2/3'), findsOneWidget);
      await tester.tap(find.text('Berikutnya'));
      await frames(tester);
      expect(find.textContaining('3/3'), findsOneWidget);
      await tester.tap(find.text('Mulai'));
      await frames(tester);
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await frames(tester);
      expect(find.text('Jeda'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await frames(tester);
      expect(find.text('Jeda'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await frames(tester);
      expect(find.text('Jeda'), findsNothing);
      await tester.binding.handlePopRoute();
      await frames(tester);
      expect(find.text('Jeda'), findsOneWidget);
      await tester.tap(find.text('Ulangi'));
      await frames(tester);
      await tester.tap(find.text('Batal'));
      await frames(tester);
      expect(find.text('Jeda'), findsOneWidget);
      await tester.tap(find.text('Lanjut'));
      await frames(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester);
      expect(find.text('Jeda'), findsOneWidget);
      await tester.tap(find.text('Beranda'));
      await frames(tester);
      expect(find.text('Lanjutkan'), findsOneWidget);
      await tester.ensureVisible(find.text('Lanjutkan'));
      await tester.tap(find.text('Lanjutkan'));
      await frames(tester);
      expect(find.text('Jeda'), findsOneWidget);
      expect(find.textContaining('1/3'), findsNothing);
      await tester.tap(find.text('Ulangi'));
      await frames(tester);
      await tester.tap(find.text('Mulai ulang'));
      await frames(tester);
      expect(find.text('Jeda'), findsNothing);
      expect(find.textContaining('1/3'), findsNothing);
      final gameWidget = tester.widget<GameWidget<FruitMergeGame>>(
        find.byWidgetPredicate((w) => w is GameWidget<FruitMergeGame>),
      );
      gameWidget.game!.gameOverFired = true;
      gameWidget.game!.onGameOver();
      await frames(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await frames(tester);
      expect(find.text('Permainan Selesai'), findsOneWidget);
      await tester.tap(find.text('Beranda'));
      await frames(tester);
      expect(find.text('Main Baru'), findsOneWidget);
      expect(find.text('Lanjutkan'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await frames(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
