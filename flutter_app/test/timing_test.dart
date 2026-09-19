import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/game/fruit_merge_game.dart';
import 'package:flutter_app/game/fruit_body.dart';

FruitMergeGame make() => FruitMergeGame(
  random: Random(42),
  onScore: (_) {},
  onMerge: (_) {},
  onDrop: () {},
  onGameOver: () {},
  onScorePop: (_, _) {},
);
void main() {
  test('30 60 120 FPS produce identical seeded physics', () {
    final boards = [30, 60, 120].map((fps) {
      final g = make();
      for (var second = 0; second < 6; second++) {
        g.dropX = 40 + second * 30;
        g.dropFruit();
        for (var frame = 0; frame < fps; frame++) {
          g.update(1 / fps);
        }
      }
      return g.snapshot('test', 0).data;
    }).toList();
    expect(boards[0], boards[1]);
    expect(boards[1], boards[2]);
  });
  test('hitch caps six steps, resume discards partial frame', () {
    final g = make()..update(5);
    expect(g.snapshot('t', 0).data['clock'], closeTo(.1, 1e-8));
    g.update(1 / 120);
    g.resumeEngine();
    g.update(1 / 120);
    expect(g.snapshot('t', 0).data['clock'], closeTo(.1, 1e-8));
    g.update(1 / 120);
    expect(g.snapshot('t', 0).data['clock'], closeTo(.1 + 1 / 60, 1e-8));
  });
  test('cooldown and combo status, watermelon celebration persists', () {
    final g = make()..dropFruit();
    expect(g.statusText.value, contains('Tunggu'));
    for (var i = 0; i < 20; i++) {
      g.update(1 / 60);
    }
    expect(g.statusText.value, contains('Siap'));
    for (var i = 0; i < 3; i++) {
      g.fruits.clear();
      g.fruits.addAll([
        FruitBody(position: Vector2(130, 300), index: 0, spawnAt: 0),
        FruitBody(position: Vector2(140, 300), index: 0, spawnAt: 0),
      ]);
      g.update(1 / 60);
    }
    expect(g.statusText.value, contains('Combo'));
    g.fruits.clear();
    g.fruits.addAll([
      FruitBody(position: Vector2(100, 300), index: 8, spawnAt: 0),
      FruitBody(position: Vector2(150, 300), index: 8, spawnAt: 0),
    ]);
    g.update(1 / 60);
    expect(g.statusText.value, contains('Semangka pertama'));
    final restored = make()..restore(g.snapshot('t', 0));
    expect(restored.madeWatermelon, true);
  });
  test('dense board benchmark stays finite', () {
    final g = make();
    for (var i = 0; i < 15; i++) {
      g.fruits.add(
        FruitBody(
          position: Vector2(30 + (i % 3) * 70, 410 - (i ~/ 3) * 70),
          index: i % 5,
          spawnAt: 0,
        ),
      );
    }
    final timer = Stopwatch()..start();
    for (var i = 0; i < 3600; i++) {
      g.update(1 / 60);
    }
    timer.stop();
    // Diagnostic host timing, not an Android rendering benchmark.
    // ignore: avoid_print
    print(
      'Dense board: 3600 steps in ${timer.elapsedMilliseconds} ms on test host',
    );
    expect(g.gameOverFired, false);
    for (final f in g.fruits) {
      expect(f.position.x.isFinite && f.position.y.isFinite, true);
      expect(
        f.position.x,
        inInclusiveRange(f.radius, FruitMergeGame.pw - f.radius),
      );
    }
  });
}
