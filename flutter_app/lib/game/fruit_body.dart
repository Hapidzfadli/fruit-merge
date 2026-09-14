import 'dart:math' as math;
import 'package:flame/game.dart';
import '../models/fruit_data.dart';

/// Custom pure-Dart physics body for one fruit — replaces the Matter.js
/// body + its `plugin` metadata (app.js:545) since flame_forge2d/Box2D was
/// dropped (native-build bug on Windows, see migration plan). Fields map
/// 1:1 onto the original:
///   position/velocity  <- Matter body.position/velocity
///   angle/angularVelocity <- Matter body.angle/angularVelocity
///   dead/spawnAt/flash/overMs <- body.plugin.{dead,spawnAt,flash,overMs}
class FruitBody {
  Vector2 position;
  Vector2 velocity;
  double angle = 0;
  double angularVelocity;
  final int index;
  bool dead = false;
  final double spawnAt; // seconds, game-clock time at spawn
  double flash;
  double overMs = 0;

  FruitBody({
    required this.position,
    required this.index,
    required this.spawnAt,
    Vector2? velocity,
    this.angularVelocity = 0,
    bool flash = false,
  })  : velocity = velocity ?? Vector2.zero(),
        flash = flash ? 1 : 0;

  FruitData get data => kFruits[index];
  double get radius => data.size / 2;

  /// Port of the per-level restitution/friction formula in spawnFruit()
  /// (app.js:536-544) — small fruits are bouncier/slicker, big fruits are
  /// heavier/grippier. This is the single most important tuning knob for
  /// keeping the "feel" close to the Matter.js original.
  double get restitution => index <= 2 ? 0.16 : math.max(0.02, 0.14 - index * 0.02);
  double get friction => index <= 2 ? 0.42 : 0.58;
}
