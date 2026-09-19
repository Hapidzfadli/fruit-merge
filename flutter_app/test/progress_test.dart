import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/state/app_state.dart';

void main() {
  test('new economy, catalog validation, rewards once across reload', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load();
    expect(s.highScore, 0);
    expect(s.coins, 0);
    expect(s.buySkin('kawaii_real'), false);
    expect(s.buySkin('missing'), false);
    s.recordMerge(1);
    s.recordMerge(1);
    expect(s.coins, 20);
    s.score = 1000;
    s.recordMerge(9);
    expect(s.coins, 170);
    await s.persist();
    final b = AppState();
    await b.load();
    b.recordMerge(9);
    expect(b.coins, 170);
    expect(b.collection, {1, 9});
    b.coins = 250;
    expect(b.buySkin('kawaii_real'), true);
    expect(b.coins, 0);
    expect(b.buySkin('kawaii_real'), false);
    await b.persist();
  });
  test('legacy progress is preserved', () async {
    SharedPreferences.setMockInitialValues({
      'fruitMergeAdventure.save': jsonEncode({
        'highScore': 1280,
        'coins': 340,
        'ownedSkins': ['gummy', 'kawaii_real'],
        'equippedSkin': 'kawaii_real',
      }),
    });
    final s = AppState();
    await s.load();
    expect(s.highScore, 1280);
    expect(s.coins, 340);
    expect(s.equippedSkin, 'kawaii_real');
  });
}
