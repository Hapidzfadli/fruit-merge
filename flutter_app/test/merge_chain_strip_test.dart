import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/game/fruit_sprites.dart';
import 'package:flutter_app/models/skin_data.dart';
import 'package:flutter_app/models/fruit_data.dart';
import 'package:flutter_app/widgets/merge_chain_strip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => FruitSprites.use(kDefaultSkinId));

  Future<void> pumpStrip(WidgetTester tester, {double width = 300}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: const MergeChainStrip())),
      ),
    ));
  }

  testWidgets('shows every fruit, growing from smallest to largest', (tester) async {
    await pumpStrip(tester);

    final fruits = tester.widgetList<FruitImage>(find.byType(FruitImage)).toList();
    expect(fruits.length, kFruits.length);

    for (var i = 0; i < fruits.length; i++) {
      expect(fruits[i].index, i, reason: 'fruits should be listed in merge order');
      if (i > 0) {
        expect(fruits[i].size, greaterThan(fruits[i - 1].size),
            reason: 'each fruit should be drawn bigger than the one before it');
      }
    }
  });

  testWidgets('has no arrows between the fruits', (tester) async {
    await pumpStrip(tester);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('fits a 300-wide board without overflowing', (tester) async {
    await pumpStrip(tester);
    expect(tester.takeException(), isNull);

    final strip = tester.getSize(find.byType(MergeChainStrip));
    expect(strip.width, lessThanOrEqualTo(300));
  });

  testWidgets('scales down instead of overflowing on a narrow screen', (tester) async {
    await pumpStrip(tester, width: 180);
    expect(tester.takeException(), isNull);
  });
}
