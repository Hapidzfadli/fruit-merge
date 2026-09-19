import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/game/fruit_sprites.dart';
import 'package:flutter_app/models/skin_data.dart';
import 'package:flutter_app/main.dart';

import 'audio_mock.dart';

void main() {
  testWidgets('App boots and shows the menu PLAY button', (
    WidgetTester tester,
  ) async {
    mockAudioChannels();
    // AppState.load() calls SharedPreferences.getInstance(), which needs a
    // mocked platform channel response in the test environment — without
    // this the future never resolves and pumpAndSettle hangs indefinitely.
    SharedPreferences.setMockInitialValues({});

    // Decoding the fruit artwork is real async I/O, which the fake clock
    // inside testWidgets won't drive. Do it up front in runAsync; the app's
    // own load() then finds the sprites already in place and returns at once.
    await tester.runAsync(() => FruitSprites.use(kDefaultSkinId));

    await tester.pumpWidget(const FruitMergeApp());
    await tester.pumpAndSettle();

    expect(find.text('New Game'), findsOneWidget);
    expect(find.textContaining('FRUIT MERGE'), findsOneWidget);
  });
}
