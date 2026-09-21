import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/game/fruit_body.dart';
import 'package:flutter_app/game/fruit_merge_game.dart';
import 'package:flutter_app/models/constants.dart';
import 'package:flutter_app/models/fruit_data.dart';

/// Runs [seconds] of simulation at a fixed 60Hz step.
void _simulate(FruitMergeGame game, double seconds) {
  const step = 1 / 60;
  for (var t = 0.0; t < seconds; t += step) {
    game.update(step);
  }
}

FruitMergeGame _makeGame({void Function()? onGameOver}) => FruitMergeGame(
      onScore: (_) {},
      onMerge: (_) {},
      onDrop: () {},
      onGameOver: onGameOver ?? () {},
      onScorePop: (_, _) {},
    );

/// Deepest overlap between any pair, in world px (0 == nothing overlaps).
double _worstOverlap(FruitMergeGame game) {
  var worst = 0.0;
  for (var i = 0; i < game.fruits.length; i++) {
    for (var j = i + 1; j < game.fruits.length; j++) {
      final a = game.fruits[i];
      final b = game.fruits[j];
      final overlap = (a.radius + b.radius) - (b.position - a.position).length;
      if (overlap > worst) worst = overlap;
    }
  }
  return worst;
}

void main() {
  group('collision resolution', () {
    test('a dense pile settles without fruits overlapping each other', () {
      final game = _makeGame();
      // Drop a spread of different-sized fruits, deliberately avoiding
      // same-index neighbours so nothing merges away and we're left with a
      // genuinely crowded board to solve.
      var y = FruitMergeGame.ph - 40.0;
      for (var row = 0; row < 5; row++) {
        for (var col = 0; col < 3; col++) {
          game.fruits.add(FruitBody(
            position: Vector2(30.0 + col * 70, y),
            index: (row + col) % 5,
            spawnAt: 0,
          ));
        }
        y -= 70;
      }

      _simulate(game, 6);

      expect(_worstOverlap(game), lessThan(0.5),
          reason: 'fruits should rest against each other, not through each other');
    });

    test('fruits keep clear of the rounded bottom corners', () {
      final game = _makeGame();
      // Small fruit shoved hard into each bottom corner — the size most
      // likely to fit inside the corner curve and get drawn sliced off.
      game.fruits.add(FruitBody(
        position: Vector2(20, FruitMergeGame.ph - 20),
        index: 0,
        spawnAt: 0,
        velocity: Vector2(-600, 600),
      ));
      game.fruits.add(FruitBody(
        position: Vector2(FruitMergeGame.pw - 20, FruitMergeGame.ph - 20),
        index: 0,
        spawnAt: 0,
        velocity: Vector2(600, 600),
      ));

      _simulate(game, 3);

      const cr = GameConstants.cornerRadius;
      for (final f in game.fruits) {
        final shrunk = cr - f.radius; // corner radius of the centre-region
        if (shrunk <= 0) continue;
        for (final centre in [
          Vector2(f.radius + shrunk, FruitMergeGame.ph - f.radius - shrunk),
          Vector2(FruitMergeGame.pw - f.radius - shrunk, FruitMergeGame.ph - f.radius - shrunk),
        ]) {
          final inCornerQuadrant =
              (centre.x < FruitMergeGame.pw / 2 ? f.position.x < centre.x : f.position.x > centre.x) &&
                  f.position.y > centre.y;
          if (inCornerQuadrant) {
            expect((f.position - centre).length, lessThanOrEqualTo(shrunk + 0.5),
                reason: 'a fruit must not poke into the rounded corner the frame clips away');
          }
        }
      }
    });

    test('fruits stay inside the walls', () {
      final game = _makeGame();
      for (var i = 0; i < 8; i++) {
        game.fruits.add(FruitBody(
          position: Vector2(FruitMergeGame.pw / 2, FruitMergeGame.ph - 30.0 - i * 40),
          index: i % 5,
          spawnAt: 0,
        ));
      }

      _simulate(game, 5);

      for (final f in game.fruits) {
        expect(f.position.x - f.radius, greaterThanOrEqualTo(-0.5));
        expect(f.position.x + f.radius, lessThanOrEqualTo(FruitMergeGame.pw + 0.5));
        expect(f.position.y + f.radius, lessThanOrEqualTo(FruitMergeGame.ph + 0.5));
      }
    });
  });

  group('board scale', () {
    test('watermelon is half the board width and sizes strictly grow', () {
      expect(kFruits.first.size, 28);
      expect(kFruits.last.size, FruitMergeGame.pw / 2);
      for (var i = 1; i < kFruits.length; i++) {
        expect(kFruits[i].size, greaterThan(kFruits[i - 1].size));
      }
    });
  });

  group('settled pile stability', () {
    // A settled bottom row must not be knocked sideways by a fruit landing
    // beside/on it — otherwise same-level neighbours get shoved together
    // and merge for free.
    double shove(int dropIndex, double dropX) {
      final game = _makeGame();
      const row = [3, 5, 2, 6, 4, 1];
      var x = 0.0;
      final bottom = <FruitBody>[];
      for (final idx in row) {
        final r = kFruits[idx].size / 2;
        if (x + r * 2 > FruitMergeGame.pw) break;
        final f = FruitBody(
          position: Vector2(x + r, FruitMergeGame.ph - r),
          index: idx,
          spawnAt: 0,
        );
        bottom.add(f);
        game.fruits.add(f);
        x += r * 2;
      }
      _simulate(game, 3);
      final before = [for (final f in bottom) f.position.clone()];

      game.currentIndex = dropIndex;
      game.dropX = dropX;
      game.dropFruit();
      _simulate(game, 2);

      var worst = 0.0;
      for (var i = 0; i < bottom.length; i++) {
        final moved = (bottom[i].position - before[i]).length;
        if (moved > worst) worst = moved;
      }
      return worst;
    }

    test('a light fruit landing on the pile barely moves the bottom row', () {
      expect(shove(0, 60), lessThan(8));
      expect(shove(0, 150), lessThan(8));
    });

    test('a mid-size fruit landing on the pile barely moves the bottom row', () {
      expect(shove(3, 100), lessThan(10));
      expect(shove(2, 200), lessThan(10));
    });
  });

  group('game over', () {
    test('fires once a fruit sits past the line for overLimitMs', () {
      var fired = false;
      final game = _makeGame(onGameOver: () => fired = true);
      // A fruit wedged above the danger line and held there.
      final f = FruitBody(position: Vector2(50, 10), index: 0, spawnAt: 0);
      game.fruits.add(f);

      // Pin it in place each frame so it can't simply fall away, emulating
      // a fruit resting on top of a full pile.
      const step = 1 / 60;
      for (var t = 0.0; t < 4.0; t += step) {
        f.position = Vector2(50, 10);
        f.velocity = Vector2.zero();
        game.update(step);
      }

      expect(fired, isTrue);
      expect(game.gameOverFired, isTrue);
    });

    test('does not fire while the fruit is still above the line but within the grace window', () {
      var fired = false;
      final game = _makeGame(onGameOver: () => fired = true);
      final f = FruitBody(position: Vector2(50, 10), index: 0, spawnAt: 0);
      game.fruits.add(f);

      const step = 1 / 60;
      // Well under overLimitMs (2.9s) — should still be in the warning state.
      for (var t = 0.0; t < 1.5; t += step) {
        f.position = Vector2(50, 10);
        f.velocity = Vector2.zero();
        game.update(step);
      }

      expect(fired, isFalse);
      expect(f.overMs, greaterThan(0), reason: 'warning timer should be running');
      expect(f.overMs, lessThan(GameConstants.overLimitMs));
    });

    test('a jostling (never-still) fruit above the line still counts down', () {
      var fired = false;
      final game = _makeGame(onGameOver: () => fired = true);
      final f = FruitBody(position: Vector2(50, 10), index: 0, spawnAt: 0);
      game.fruits.add(f);

      const step = 1 / 60;
      for (var t = 0.0; t < 4.0; t += step) {
        // Keep it in the danger zone but moving fast the whole time — the
        // old rule only ticked the timer for fruit that had come to rest,
        // so a restless pile could sit above the line forever.
        f.position = Vector2(50, 10);
        f.velocity = Vector2(400, -200);
        game.update(step);
      }

      expect(fired, isTrue);
    });

    test('timer resets when the fruit drops back below the line', () {
      var fired = false;
      final game = _makeGame(onGameOver: () => fired = true);
      final f = FruitBody(position: Vector2(50, 10), index: 0, spawnAt: 0);
      game.fruits.add(f);

      const step = 1 / 60;
      // Hold it in the danger zone long enough to build up the timer...
      for (var t = 0.0; t < 2.0; t += step) {
        f.position = Vector2(50, 10);
        f.velocity = Vector2.zero();
        game.update(step);
      }
      expect(f.overMs, greaterThan(0));

      // ...then let it fall away before the limit.
      _simulate(game, 2.0);

      expect(fired, isFalse, reason: 'escaping the danger zone must cancel game over');
      expect(f.overMs, 0);
    });
  });

  group('merging', () {
    test('two touching same-level fruits become one of the next level', () {
      var mergedLevel = -1;
      var scored = 0;
      final game = FruitMergeGame(
        onScore: (amount) => scored += amount,
        onMerge: (level) => mergedLevel = level,
        onDrop: () {},
        onGameOver: () {},
        onScorePop: (_, _) {},
      );
      final r = kFruits[0].size / 2;
      game.fruits.add(FruitBody(position: Vector2(60, FruitMergeGame.ph - r), index: 0, spawnAt: 0));
      game.fruits.add(FruitBody(position: Vector2(60 + r, FruitMergeGame.ph - r), index: 0, spawnAt: 0));

      game.update(1 / 60);

      expect(game.fruits.length, 1);
      expect(game.fruits.single.index, 1);
      expect(mergedLevel, 1);
      expect(scored, GameConstants.mergeScore[1]);
    });

    test('the largest fruit does not merge further', () {
      final game = _makeGame();
      final top = kFruits.length - 1;
      final r = kFruits[top].size / 2;
      game.fruits.add(FruitBody(position: Vector2(80, FruitMergeGame.ph - r), index: top, spawnAt: 0));
      game.fruits.add(FruitBody(position: Vector2(80 + r, FruitMergeGame.ph - r), index: top, spawnAt: 0));

      _simulate(game, 1);

      expect(game.fruits.length, 2);
    });
  });
}
