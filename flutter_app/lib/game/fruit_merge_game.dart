import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show Colors;

import '../models/constants.dart';
import '../models/fruit_data.dart';
import 'fruit_body.dart';
import 'fruit_sprites.dart';
import '../models/run_snapshot.dart';

/// Custom pure-Dart 2D physics + rendering for the merge board. Replaces
/// Matter.js (app.js:496-568,570-631) — flame_forge2d/Box2D was dropped
/// after hitting a native-build bug on Windows (see migration plan). All
/// bodies here are circles, so a hand-rolled O(n²) collision pass is both
/// simpler and plenty fast for the small fruit counts this game has.
///
/// World units are the same logical pixels app.js used (PW x PH), letting
/// FRUITS/GameConstants sizes carry over unchanged. Velocities are in
/// px/s (real seconds) rather than Matter's per-frame units — anywhere the
/// original had an explicit px/frame velocity (e.g. vy: 2), it's converted
/// via *60 (Matter's implicit ~60Hz reference frame) and re-tuned from
/// there; thresholds in postStep-equivalent damping are re-picked for this
/// unit system since Matter's arbitrary internal scale doesn't translate.
class FruitMergeGame extends FlameGame with TapCallbacks {
  static const double pw = GameConstants.pw;
  static const double ph = GameConstants.ph;
  static const double lineY = GameConstants.lineY;
  static const double cornerRadius = GameConstants.cornerRadius;
  static const double gravity = 1400; // px/s^2 — tune to taste
  static const double overLimitMs = GameConstants.overLimitMs;
  static const double dropCooldownMs = GameConstants.dropCooldownMs;
  static const double spawnAnimMs = GameConstants.spawnAnimMs;

  /// Overlap-relaxation sweeps per substep. The analogue of Matter.js's
  /// positionIterations (app.js:506 used 14); circles-only contacts
  /// converge much faster than Matter's general solver, so fewer suffice.
  static const int _positionIterations = 32;

  /// Approach speed (px/s) below which a contact is treated as resting
  /// rather than an impact — see the restitution note in
  /// [_resolveCirclePair]. Roughly one frame's worth of gravity.
  static const double _restingSpeed = 30;

  /// Speed (px/s) below which a fruit counts as part of the settled pile,
  /// and how much heavier it then behaves in a collision — see
  /// [_effectiveMass].
  static const double _settledSpeed = 150;
  static const double _settledMassBoost = 8;

  /// Terminal fall speed (px/s). Without it a fruit dropped from the top
  /// lands at ~1100 px/s and its impact throws the pile sideways.
  static const double _maxFallSpeed = 900;

  final void Function(int amount) onScore;
  final void Function(int level) onMerge; // caller plays SFX + vibration
  final VoidCallback onDrop; // caller plays SFX
  final VoidCallback onGameOver; // caller plays SFX + vibration + stops music
  final void Function(Vector2 worldPos, int amount) onScorePop;

  final List<FruitBody> fruits = [];
  double _clock = 0;
  double _lastDropAtMs = -1e9;
  bool gameOverFired = false;

  late final math.Random _random;
  late int currentIndex;
  late final ValueNotifier<int> nextIndexNotifier;
  double _accumulator = 0;
  double dropX = pw / 2;
  final ValueNotifier<String> statusText = ValueNotifier('Ready • tap the board');
  bool madeWatermelon = false;
  int _combo = 0;
  double _lastMerge = -100;
  double _celebrateUntil = -1;
  void _updateStatus() {
    final danger = fruits
        .where((f) => !f.dead)
        .fold<double>(0, (value, f) => math.max(value, f.overMs));
    final cooling = _clock * 1000 - _lastDropAtMs < dropCooldownMs;
    statusText.value = danger > 0
        ? 'Danger • ${((overLimitMs - danger) / 1000).clamp(0, 2.9).toStringAsFixed(1)} s'
        : _clock < _celebrateUntil
        ? 'First watermelon! 🍉'
        : _combo >= 3 && _clock - _lastMerge <= 1
        ? 'Combo ×$_combo!'
        : cooling
        ? 'Please wait…'
        : 'Ready • tap the board';
  }

  RunSnapshot snapshot(String id, int score) => RunSnapshot({
    'version': 1,
    'id': id,
    'score': score,
    'clock': _clock,
    'watermelon': madeWatermelon,
    'combo': _combo,
    'lastMerge': _lastMerge,
    'current': currentIndex,
    'next': nextIndexNotifier.value,
    'dropX': dropX,
    'cooldown': (dropCooldownMs - (_clock * 1000 - _lastDropAtMs)).clamp(
      0,
      dropCooldownMs,
    ),
    'fruits': fruits
        .where((f) => !f.dead)
        .map(
          (f) => {
            'index': f.index,
            'x': f.position.x,
            'y': f.position.y,
            'vx': f.velocity.x,
            'vy': f.velocity.y,
            'angle': f.angle,
            'angular': f.angularVelocity,
            'age': _clock - f.spawnAt,
            'over': f.overMs,
            'flash': f.flash,
          },
        )
        .toList(),
  });

  void restore(RunSnapshot snapshot) {
    final d = snapshot.data;
    resetBoard();
    _clock = (d['clock'] as num).toDouble();
    madeWatermelon = d['watermelon'] == true;
    _combo = (d['combo'] as int?) ?? 0;
    _lastMerge = (d['lastMerge'] as num?)?.toDouble() ?? -100;
    currentIndex = d['current'] as int;
    nextIndexNotifier.value = d['next'] as int;
    dropX = (d['dropX'] as num).toDouble().clamp(pw * .08, pw * .92);
    _lastDropAtMs = _clock * 1000 - dropCooldownMs + (d['cooldown'] as num);
    for (final f in d['fruits'] as List) {
      fruits.add(
        FruitBody(
            position: Vector2(
              (f['x'] as num).toDouble(),
              (f['y'] as num).toDouble(),
            ),
            index: f['index'] as int,
            spawnAt: _clock - (f['age'] as num),
            velocity: Vector2(
              (f['vx'] as num).toDouble(),
              (f['vy'] as num).toDouble(),
            ),
            angularVelocity: (f['angular'] as num).toDouble(),
          )
          ..angle = (f['angle'] as num).toDouble()
          ..overMs = (f['over'] as num).toDouble()
          ..flash = (f['flash'] as num).toDouble(),
      );
    }
    pauseEngine();
  }

  int _randomDropIndex() => _random.nextInt(5);

  FruitMergeGame({
    required this.onScore,
    required this.onMerge,
    required this.onDrop,
    required this.onGameOver,
    required this.onScorePop,
    math.Random? random,
  }) {
    _random = random ?? math.Random();
    currentIndex = _randomDropIndex();
    nextIndexNotifier = ValueNotifier(_randomDropIndex());
  }

  @override
  void resumeEngine() {
    _accumulator = 0;
    super.resumeEngine();
  }

  // FlameGame paints solid black behind everything by default — make it
  // transparent so the board's translucent Container decoration (set in
  // GamePage, mirroring .board's CSS gradient) shows through instead.
  @override
  Color backgroundColor() => const Color(0x00000000);

  // ---------------- Update loop ----------------

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOverFired || !dt.isFinite || dt <= 0) return;
    const fixedStep = 1 / 60;
    _accumulator = math.min(_accumulator + dt, fixedStep * 6);
    var steps = 0;
    while (_accumulator + 1e-10 >= fixedStep && steps < 6 && !gameOverFired) {
      _accumulator = math.max(0, _accumulator - fixedStep);
      _clock += fixedStep;
      _simulateStep(fixedStep);
      steps++;
    }
  }

  void _simulateStep(double stepDt) {
    const substeps = 2;
    final sub = stepDt / substeps;
    for (var s = 0; s < substeps; s++) {
      for (final f in fruits) {
        if (f.dead) continue;
        f.velocity.y = math.min(f.velocity.y + gravity * sub, _maxFallSpeed);
        // Cap speed so a deep-overlap collision impulse (e.g. several
        // fruits merging into a tight spot at once) can't snowball into
        // NaN/Infinity over a few frames — that previously surfaced as a
        // Flutter assertion crash when the bad value reached Color.alpha.
        const maxSpeed = 2600.0;
        if (f.velocity.length2 > maxSpeed * maxSpeed) {
          f.velocity = f.velocity.normalized() * maxSpeed;
        }
        f.position += f.velocity * sub;
        f.angle += f.angularVelocity * sub;
        _resolveWalls(f);
      }
      // Velocity pass: bounce/friction impulses, plus merge detection.
      _resolveCollisionsAndMerges();
      // Position passes: pushing A out of B routinely shoves A into C, so a
      // single pass leaves visible overlap in a dense pile. Relax the whole
      // set repeatedly (Gauss-Seidel style) until fruits actually sit
      // against each other instead of through each other, re-clamping to
      // the walls each round so separation can't squeeze one outside.
      for (var it = 0; it < _positionIterations; it++) {
        _separateOverlaps();
        for (final f in fruits) {
          if (!f.dead) _clampToWalls(f);
        }
      }
    }
    _postStep(stepDt);
    fruits.removeWhere((f) => f.dead);
    _updateStatus();
  }

  /// Pushes [f] back inside the board and reports which way it was moved
  /// (zero if it was already inside).
  ///
  /// The board's bottom corners are rounded to match the drawn frame — with
  /// a square physics boundary, a fruit could settle into the visual corner
  /// curve, where it looked sliced off by the frame and got permanently
  /// squeezed (hence the endless jitter). Containing a circle of radius r
  /// inside a rounded rect means keeping its centre inside the same rect
  /// inset by r, whose corner radius shrinks to `cornerRadius - r` (never
  /// below zero, for fruit bigger than the corner itself).
  Vector2 _boardCorrection(FruitBody f) {
    final r = f.radius;
    final before = f.position.clone();
    var x = f.position.x.clamp(r, math.max(r, pw - r)).toDouble();
    var y = math.min(f.position.y, ph - r);

    final cr = math.max(0.0, cornerRadius - r);
    if (cr > 0 && y > ph - r - cr) {
      final cornerCentreX = x < pw / 2 ? r + cr : pw - r - cr;
      final inCornerColumn = x < pw / 2 ? x < cornerCentreX : x > cornerCentreX;
      if (inCornerColumn) {
        final centre = Vector2(cornerCentreX, ph - r - cr);
        final offset = Vector2(x, y) - centre;
        final d = offset.length;
        if (d > cr && d > 0.0001) {
          final pulled = centre + offset * (cr / d);
          x = pulled.x;
          y = pulled.y;
        }
      }
    }

    f.position.setValues(x, y);
    return f.position - before;
  }

  /// Position-only board containment, safe to run repeatedly inside the
  /// relaxation loop (unlike [_resolveWalls], which also kills velocity).
  void _clampToWalls(FruitBody f) => _boardCorrection(f);

  void _resolveWalls(FruitBody f) {
    final moved = _boardCorrection(f);
    if (moved.x != 0) f.velocity.x = 0;
    if (moved.y != 0) {
      if (f.velocity.y > 0) f.velocity.y = 0;
      // Floor friction (Matter wallOpts had no restitution, only friction —
      // app.js:509) damps horizontal velocity while resting on the floor.
      f.velocity.x *= (1 - f.friction * 0.3).clamp(0.0, 1.0);
    }
  }

  /// One relaxation sweep: push every overlapping pair apart along their
  /// centre line, splitting the correction by mass. Touches positions only
  /// — velocities are handled once per substep in [_resolveCirclePair], so
  /// repeating this is cheap and doesn't inject energy.
  void _separateOverlaps() {
    final n = fruits.length;
    for (var i = 0; i < n; i++) {
      final a = fruits[i];
      if (a.dead) continue;
      for (var j = i + 1; j < n; j++) {
        final b = fruits[j];
        if (b.dead) continue;
        final delta = b.position - a.position;
        var dist = delta.length;
        final minDist = a.radius + b.radius;
        if (dist >= minDist) continue;

        Vector2 normal;
        if (dist <= 0.0001) {
          // Exactly concentric (can happen right after a merge spawns on
          // top of another fruit) — no valid centre line, so pick one.
          normal = Vector2(0, -1);
          dist = 0.0001;
        } else {
          normal = delta / dist;
        }
        final overlap = minDist - dist;
        final massA = _effectiveMass(a);
        final massB = _effectiveMass(b);
        final totalMass = massA + massB;
        a.position -= normal * (overlap * (massB / totalMass));
        b.position += normal * (overlap * (massA / totalMass));
      }
    }
  }

  void _resolveCollisionsAndMerges() {
    final toMerge = <(FruitBody, FruitBody)>[];
    final n = fruits.length;
    for (var i = 0; i < n; i++) {
      final a = fruits[i];
      if (a.dead) continue;
      for (var j = i + 1; j < n; j++) {
        final b = fruits[j];
        if (b.dead) continue;
        final delta = b.position - a.position;
        final dist = delta.length;
        final minDist = a.radius + b.radius;
        if (dist >= minDist || dist <= 0.0001) continue;

        // Port of collisionStart merge detection (app.js:515-524): same
        // level, neither already flagged dead, not already at max level.
        if (a.index == b.index && a.index < kFruits.length - 1) {
          a.dead = true;
          b.dead = true;
          toMerge.add((a, b));
          break; // `a` is gone — stop testing it against the rest of j.
        }
        _resolveCirclePair(a, b, delta, dist, minDist);
      }
    }
    for (final (a, b) in toMerge) {
      _spawnMergeResult(a, b);
    }
  }

  /// Effective mass of [f] in a contact. A fruit that is already settled
  /// belongs to the pile: it is braced by the floor, the walls and the fruit
  /// stacked on it, so a falling fruit must not be able to shove it around
  /// like a free body (that let the player nudge same-level neighbours
  /// together at the bottom and merge them for free).
  double _effectiveMass(FruitBody f) {
    final base = f.radius * f.radius;
    return f.velocity.length2 < _settledSpeed * _settledSpeed
        ? base * _settledMassBoost
        : base;
  }

  void _resolveCirclePair(
    FruitBody a,
    FruitBody b,
    Vector2 delta,
    double dist,
    double minDist,
  ) {
    final normal = delta / dist;
    final overlap = minDist - dist;
    final massA = _effectiveMass(a);
    final massB = _effectiveMass(b);
    final totalMass = massA + massB;

    a.position -= normal * (overlap * (massB / totalMass));
    b.position += normal * (overlap * (massA / totalMass));

    final relVel = b.velocity - a.velocity;
    final velAlongNormal = relVel.dot(normal);
    if (velAlongNormal >= 0) return; // separating already

    // Restitution only counts for real impacts. On a resting contact
    // gravity re-adds a sliver of approach speed every frame, and bouncing
    // that back turns into perpetual micro-jitter — so below this speed the
    // collision is treated as fully inelastic and the pile goes still.
    final e = -velAlongNormal < _restingSpeed
        ? 0.0
        : math.min(a.restitution, b.restitution);
    final invMassA = 1 / massA;
    final invMassB = 1 / massB;
    final jImpulse = -(1 + e) * velAlongNormal / (invMassA + invMassB);
    final impulse = normal * jImpulse;
    a.velocity -= impulse * invMassA;
    b.velocity += impulse * invMassB;

    // Simple tangential friction so stacked fruit don't slide forever.
    final tangent = Vector2(-normal.y, normal.x);
    final velAlongTangent = relVel.dot(tangent);
    final frictionCoeff = (a.friction + b.friction) / 2;
    final frictionImpulseMag = -velAlongTangent * frictionCoeff * 0.6;
    final frictionImpulse = tangent * frictionImpulseMag;
    a.velocity -= frictionImpulse * invMassA;
    b.velocity += frictionImpulse * invMassB;
  }

  void _spawnMergeResult(FruitBody a, FruitBody b) {
    final newIndex = a.index + 1;
    _combo = _clock - _lastMerge <= 1 ? _combo + 1 : 1;
    _lastMerge = _clock;
    if (newIndex == 9 && !madeWatermelon) {
      madeWatermelon = true;
      _celebrateUntil = _clock + 2;
    }
    final r = kFruits[newIndex].size / 2;
    final mid = (a.position + b.position) / 2;
    final x = mid.x.clamp(r + 1, pw - r - 1);
    final y = math.min(mid.y, ph - r - 1);

    final merged = FruitBody(
      position: Vector2(x, y),
      index: newIndex,
      spawnAt: _clock,
      velocity: Vector2(
        (a.velocity.x + b.velocity.x) / 2,
        -144,
      ), // app.js vy:-2.4 * 60
      angularVelocity: (_random.nextDouble() - 0.5) * 3.6,
      flash: true,
    );
    fruits.add(merged);

    final scoreGain = GameConstants.mergeScore[newIndex];
    onScore(scoreGain);
    onMerge(newIndex);
    onScorePop(Vector2(x, y), scoreGain);
  }

  void _postStep(double dt) {
    for (final f in fruits) {
      if (f.dead) continue;
      final speed = f.velocity.length;
      // Extra rotational damping once nearly still — app.js:556.
      f.angularVelocity *= speed < 20 ? 0.55 : 0.9;
      if (speed < 4 && f.angularVelocity.abs() < 0.05) {
        f.velocity *= 0.5;
        f.angularVelocity = 0;
      }
      f.flash = math.max(
        0,
        f.flash - dt * 3.3,
      ); // ~0.055/frame @ 60fps — app.js:561

      // Danger timer. Unlike app.js (logic.md §8.4) this deliberately does
      // NOT require the fruit to be settled: the rule is simply "bottom of
      // the fruit is above the line" (the whole fruit is over it, a fruit
      // merely poking over the line is still fine) — a fruit jostling around
      // up there is just as lost as one sitting still, and requiring
      // stillness meant a restless pile could dodge game over indefinitely.
      // The grace period still applies so a fruit that spawns at the top
      // and is merely falling through the zone doesn't flash a warning.
      final ageMs = (_clock - f.spawnAt) * 1000;
      if (ageMs > 500 && f.position.y + f.radius < lineY) {
        f.overMs += dt * 1000;
      } else {
        f.overMs = 0; // dropped back below the line — reset, per the spec
      }
      if (f.overMs > overLimitMs && !gameOverFired) {
        gameOverFired = true;
        onGameOver();
        return;
      }
    }
  }

  // ---------------- Drop control ----------------

  void dropFruit() {
    if (gameOverFired) return;
    final nowMs = _clock * 1000;
    if (nowMs - _lastDropAtMs < dropCooldownMs) return;
    _lastDropAtMs = nowMs;

    final idx = currentIndex;
    final r = kFruits[idx].size / 2;
    final x = dropX.clamp(r + 1, pw - r - 1);
    fruits.add(
      FruitBody(
        position: Vector2(x, r + 2),
        index: idx,
        spawnAt: _clock,
        velocity: Vector2(0, 120), // app.js vy:2 * 60
      ),
    );
    onDrop();
    currentIndex = nextIndexNotifier.value;
    nextIndexNotifier.value = _randomDropIndex();
    _updateStatus();
  }

  void resetBoard() {
    _accumulator = 0;
    madeWatermelon = false;
    _combo = 0;
    _lastMerge = -100;
    _celebrateUntil = -1;
    statusText.value = 'Ready • tap the board';
    fruits.clear();
    gameOverFired = false;
    _clock = 0;
    _lastDropAtMs = -1e9;
    currentIndex = _randomDropIndex();
    nextIndexNotifier.value = _randomDropIndex();
    dropX = pw / 2;
  }

  // ---------------- Input ----------------

  ({double scale, double dx, double dy}) _fitTransform() {
    final scale = math.min(size.x / pw, size.y / ph);
    return (
      scale: scale,
      dx: (size.x - pw * scale) / 2,
      dy: (size.y - ph * scale) / 2,
    );
  }

  Vector2 _screenToWorld(Vector2 local) {
    final t = _fitTransform();
    return Vector2((local.x - t.dx) / t.scale, (local.y - t.dy) / t.scale);
  }

  void _updateAimFromScreen(Vector2 local) {
    final world = _screenToWorld(local);
    dropX = world.x.clamp(pw * 0.08, pw * 0.92);
  }

  /// Called from GamePage's MouseRegion.onHover — desktop/web mice generate
  /// real hover events with no button pressed, so the aim preview can track
  /// the cursor continuously even before a click, matching the original
  /// web version's `pointermove` handler (app.js:670-676).
  void updateAimFromScreen(Offset local) =>
      _updateAimFromScreen(Vector2(local.dx, local.dy));

  // A single tap/click both aims AND drops in one motion — no more
  // press-drag-release. onTapDown (not onTapUp) fires unambiguously the
  // instant the pointer goes down, so there's no gesture-arena delay
  // waiting to see if this becomes a drag before it responds.
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _updateAimFromScreen(event.localPosition);
    dropFruit();
  }

  /// Converts a world-space point (same units as [fruits] positions) to
  /// this game's local widget pixel coordinates — used by GamePage to
  /// place the score-pop overlay (app.js spawnScorePop, app.js:588-593)
  /// which lives in the Flutter widget tree, not the canvas.
  Offset worldToScreen(Vector2 world) {
    final t = _fitTransform();
    return Offset(world.x * t.scale + t.dx, world.y * t.scale + t.dy);
  }

  // ---------------- Rendering ----------------

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = _fitTransform();
    canvas.save();
    canvas.translate(t.dx, t.dy);
    canvas.scale(t.scale);

    _drawDangerLine(canvas);
    for (final f in fruits) {
      _drawFruit(canvas, f);
    }
    if (!gameOverFired) _drawDropGuide(canvas);

    canvas.restore();
  }

  void _drawDangerLine(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0x8CFF7896)
      ..strokeWidth = 2;
    const dashLen = 6.0, gapLen = 5.0;
    double x = 0;
    while (x < pw) {
      canvas.drawLine(
        Offset(x, lineY),
        Offset(math.min(x + dashLen, pw), lineY),
        paint,
      );
      x += dashLen + gapLen;
    }
  }

  void _drawDropGuide(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0x73FF6B4A)
      ..strokeWidth = 2;
    const dashLen = 6.0, gapLen = 5.0;
    double y = 0;
    while (y < ph) {
      canvas.drawLine(
        Offset(dropX, y),
        Offset(dropX, math.min(y + dashLen, ph)),
        paint,
      );
      y += dashLen + gapLen;
    }

    final f = kFruits[currentIndex];
    canvas.save();
    canvas.translate(dropX, f.size / 2);
    FruitSprites.instance[currentIndex].paint(canvas, f.size);
    canvas.restore();
  }

  void _drawFruit(Canvas canvas, FruitBody f) {
    // Defensive guard: num.clamp() throws ArgumentError on NaN, which would
    // otherwise crash the whole render pass for one bad body. Skip drawing
    // it for a frame rather than taking down the board.
    if (f.position.x.isNaN || f.position.y.isNaN || f.angle.isNaN) return;

    final size = f.data.size;
    final ageMs = (_clock - f.spawnAt) * 1000;
    final p = (ageMs / spawnAnimMs).clamp(0.0, 1.0);
    final amp = 0.26 * (1 - p) * math.cos(p * math.pi * 2.2);
    final sx = 1 + amp, sy = 1 - amp;
    final deg = (f.angle * 180 / math.pi).clamp(-18.0, 18.0);

    // Danger-zone warning state: f.overMs counts up from 0 while the fruit
    // sits above lineY (see _postStep) and resets to 0 the moment it drops
    // back below the line or gets merged away. While it's running the
    // fruit is drawn washed-out and shaken, urgency escalating until
    // overLimitMs triggers game over.
    final isWarning = f.overMs > 0;
    final warningT = (f.overMs / overLimitMs).clamp(0.0, 1.0);
    final shakeX = isWarning ? math.sin(_clock * 40) * 3 * warningT : 0.0;
    // Brief "happy pop" right after a merge, riding the same flash decay
    // used for the ring effect (1 -> 0 over ~SPAWN_ANIM-ish time).
    final isMergePop = f.flash > 0.3;

    canvas.save();
    canvas.translate(f.position.x + shakeX, f.position.y);
    canvas.rotate(deg * math.pi / 180);
    canvas.scale(sx, sy);
    FruitSprites.instance[f.index].paint(
      canvas,
      size,
      expression: isMergePop
          ? FruitExpression.mergePop
          : isWarning
          ? FruitExpression.warning
          : FruitExpression.normal,
    );
    canvas.restore();

    if (f.flash > 0.02) {
      canvas.save();
      canvas.translate(f.position.x, f.position.y);
      final ringScale = 1 + (1 - f.flash) * 0.5;
      canvas.drawCircle(
        Offset.zero,
        (size / 2 + 7) * ringScale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: f.flash),
      );
      canvas.restore();
    }
  }
}
