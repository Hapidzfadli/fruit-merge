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
      await tester.ensureVisible(find.text('New Game'));
      await tester.tap(find.text('New Game'));
      await frames(tester);
      expect(find.textContaining('1/3'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await frames(tester);
      expect(find.textContaining('2/3'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await frames(tester);
      expect(find.textContaining('3/3'), findsOneWidget);
      await tester.tap(find.text('Start'));
      await frames(tester);
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await frames(tester);
      expect(find.text('Paused'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await frames(tester);
      expect(find.text('Paused'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await frames(tester);
      expect(find.text('Paused'), findsNothing);
      await tester.binding.handlePopRoute();
      await frames(tester);
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(find.text('Restart'));
      await frames(tester);
      await tester.tap(find.text('Cancel'));
      await frames(tester);
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(find.text('Resume'));
      await frames(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester);
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(find.text('Home'));
      await frames(tester);
      expect(find.text('Continue'), findsOneWidget);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await frames(tester);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.textContaining('1/3'), findsNothing);
      await tester.tap(find.text('Restart'));
      await frames(tester);
      await tester.tap(find.text('Restart Game'));
      await frames(tester);
      expect(find.text('Paused'), findsNothing);
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
      expect(find.text('Game Over'), findsOneWidget);
      await tester.tap(find.text('Home'));
      await frames(tester);
      expect(find.text('New Game'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await frames(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
