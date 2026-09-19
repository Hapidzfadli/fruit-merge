import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/audio/sfx_service.dart';
import 'package:flutter_app/state/app_state.dart';
import 'package:flutter_app/game/fruit_sprites.dart';
import 'package:flutter_app/models/skin_data.dart';
import 'package:flutter_app/ui/menu_page.dart';
import 'package:flutter_app/ui/settings_page.dart';
import 'package:flutter_app/ui/game_over_page.dart';
import 'package:flutter_app/ui/ranking_page.dart';
import 'package:flutter_app/ui/collection_page.dart';
import 'package:flutter_app/ui/shop_page.dart';

import 'audio_mock.dart';

void main() {
  test('ranking sorts ties by newest, caps at ten and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    for (var i = 0; i < 12; i++) {
      state.score = 100;
      state.recordGameOver(runId: '$i', highestLevel: i % 10);
    }
    await state.persist();
    final restored = AppState();
    await restored.load();
    expect(restored.ranking.length, 10);
    expect(restored.ranking.first['level'], 1);
    expect(restored.recordGameOver(runId: '11'), 0);
  });
  for (final width in [320.0, 430.0]) {
    testWidgets('screens fit width $width and 130 percent text', (
      tester,
    ) async {
      mockAudioChannels();
      tester.view.physicalSize = Size(width, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() => FruitSprites.use(kDefaultSkinId));
      final state = AppState();
      final sfx = SfxService(state);
      for (final screen in [
        const MenuPage(),
        const SettingsPage(),
        const RankingPage(),
        const CollectionPage(),
        const ShopPage(),
        const GameOverPage(score: 1234, earned: 123, newRecord: true),
      ]) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: state),
              Provider.value(value: sfx),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: screen,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
      }
      await tester.pumpWidget(const SizedBox());
      sfx.dispose();
    });
  }
}
