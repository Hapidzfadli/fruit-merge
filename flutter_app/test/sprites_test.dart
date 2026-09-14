import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/game/fruit_sprites.dart';
import 'package:flutter_app/models/skin_data.dart';
import 'package:flutter_app/models/fruit_data.dart';

/// Renders one fruit centred on a square canvas and returns its alpha mask.
Future<({List<bool> opaque, int side})> _render(int index, double bodySize, int side) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()));
  canvas.translate(side / 2, side / 2);
  FruitSprites.instance[index].paint(canvas, bodySize);
  final picture = recorder.endRecording();
  final image = await picture.toImage(side, side);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  return (
    opaque: List<bool>.generate(side * side, (i) => bytes[i * 4 + 3] > 40),
    side: side,
  );
}

/// Renders one fruit centred on a square canvas and returns its raw pixels.
Future<({Uint8List rgba, int side})> _renderRgba(
  int index,
  double bodySize,
  int side, {
  FruitExpression expression = FruitExpression.normal,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()));
  canvas.translate(side / 2, side / 2);
  FruitSprites.instance[index].paint(canvas, bodySize, expression: expression);
  final picture = recorder.endRecording();
  final image = await picture.toImage(side, side);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return (rgba: data!.buffer.asUint8List(), side: side);
}

Future<Uint8List> _pixels(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => FruitSprites.use(kDefaultSkinId));

  test('every fruit level has artwork with sane body metrics', () {
    expect(FruitSprites.instance.sprites.length, kFruits.length);
    for (var i = 0; i < kFruits.length; i++) {
      final s = FruitSprites.instance[i];
      expect(s.image.width, greaterThan(0), reason: '${kFruits[i].name} image');
      // The body must be a real chunk of the art, and can't exceed its width.
      expect(s.bodyScale, inInclusiveRange(0.5, 1.0), reason: '${kFruits[i].name} bodyScale');
      expect(s.bodyCx, inInclusiveRange(0.2, 0.8), reason: '${kFruits[i].name} bodyCx');
      expect(s.bodyCy, inInclusiveRange(0.2, 0.95), reason: '${kFruits[i].name} bodyCy');
    }
  });

  test('artwork is drawn centred on the collision circle it represents', () async {
    const bodySize = 100.0;
    const side = 300;
    const centre = side / 2;

    for (var i = 0; i < kFruits.length; i++) {
      final rendered = await _render(i, bodySize, side);

      // Scan the row through the body's centre: that horizontal slice is the
      // circle's diameter, so it should span the full body size, centred.
      var left = -1, right = -1;
      final row = centre.toInt();
      for (var x = 0; x < side; x++) {
        if (rendered.opaque[row * side + x]) {
          left = left == -1 ? x : left;
          right = x;
        }
      }
      expect(left, isNot(-1), reason: '${kFruits[i].name} drew nothing on its centre row');

      final drawnCentre = (left + right) / 2;
      final drawnWidth = (right - left).toDouble();

      expect((drawnCentre - centre).abs(), lessThan(bodySize * 0.06),
          reason: '${kFruits[i].name} is off-centre from its collision circle');
      // Art may be a touch wider than the inscribed body circle (a cherry's
      // shoulders, say) but must not fall short of it, or fruit would look
      // like it floats apart from its neighbours.
      expect(drawnWidth, greaterThan(bodySize * 0.9),
          reason: '${kFruits[i].name} is narrower than its collision circle');
      expect(drawnWidth, lessThan(bodySize * 1.2),
          reason: '${kFruits[i].name} overflows its collision circle badly');
    }
  });

  test('a topper is drawn above the collision circle, never below it', () async {
    const bodySize = 100.0;
    const side = 300;
    const centre = side / 2;

    // Pineapple: the crown is the largest overhang in the set.
    final rendered = await _render(7, bodySize, side);
    var top = -1, bottom = -1;
    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        if (rendered.opaque[y * side + x]) {
          top = top == -1 ? y : top;
          bottom = y;
          break;
        }
      }
    }

    expect(top, lessThan(centre - bodySize / 2),
        reason: 'the crown should stick out above the collision circle');
    expect(bottom, lessThan(centre + bodySize / 2 + bodySize * 0.06),
        reason: 'nothing should hang below the circle, or the fruit would look sunk into the floor');
  });

  test('the skin carries one face layer, shared by every fruit', () async {
    final faces = FruitSprites.instance[0].faces;
    expect(faces, isNotNull, reason: 'the default skin composites a separate face layer');

    // One face for the whole set is the point of splitting it off: it keeps
    // the expression identical from cherry to watermelon.
    for (var i = 1; i < kFruits.length; i++) {
      expect(identical(FruitSprites.instance[i].faces, faces), isTrue,
          reason: '${kFruits[i].name} should share the set\'s face, not carry its own');
    }

    // The two moods have to sit on the same grid, or swapping one for the
    // other would shift the eyes and read as a jump rather than a reaction.
    expect(faces!.panic.width, faces.idle.width);
    expect(faces.panic.height, faces.idle.height);

    final idle = await _pixels(faces.idle);
    final panic = await _pixels(faces.panic);
    expect(idle, isNot(orderedEquals(panic)), reason: 'the two moods should be different drawings');
  });

  test('a fruit in the danger zone wears its panic face over the washed-out body', () async {
    const bodySize = 120.0;
    const side = 200;

    // The warning colour matrix adds +70 to red, so nothing that went through
    // it survives as dark. Only the face layer, drawn on top unfiltered, can
    // be — and that is exactly what keeps the X eyes readable against the pale
    // fruit. Measured: 37-39 with the face, 61 without it.
    for (final expression in [FruitExpression.normal, FruitExpression.warning]) {
      final rendered = await _renderRgba(4, bodySize, side, expression: expression);
      var darkest = 255;
      for (var i = 0; i < side * side; i++) {
        if (rendered.rgba[i * 4 + 3] > 200) darkest = math.min(darkest, rendered.rgba[i * 4]);
      }
      expect(darkest, lessThan(50), reason: 'the face should be drawn unfiltered on top ($expression)');
    }
  });

  test('equipping a skin swaps the artwork and tells widgets to repaint', () async {
    final other = kSkins.firstWhere((sk) => sk.id != kDefaultSkinId);
    addTearDown(() => FruitSprites.use(kDefaultSkinId));

    final before = FruitSprites.instance;
    final generationBefore = FruitSprites.generation.value;

    await FruitSprites.use(other.id);
    expect(identical(FruitSprites.instance, before), isFalse,
        reason: 'equipping ${other.name} should put a different set of artwork in play');
    expect(FruitSprites.generation.value, greaterThan(generationBefore),
        reason: 'FruitImage repaints off this counter — without it the shop keeps the old fruit on screen');

    // Both skins stay decoded, which is what lets the shop draw every card
    // with the skin it is actually selling.
    expect(FruitSprites.cached(kDefaultSkinId), same(before));

    // Re-equipping what is already on should not churn the counter.
    final settled = FruitSprites.generation.value;
    await FruitSprites.use(other.id);
    expect(FruitSprites.generation.value, settled);
  });

  test('a skin without a layered face still loads, and just fades in danger', () async {
    final baked = kSkins.where((sk) => !sk.layeredFace);
    expect(baked, isNotEmpty, reason: 'kawaii_real paints its face into each fruit');

    for (final sk in baked) {
      final sprites = await FruitSprites.ensureLoaded(sk.id);
      expect(sprites.sprites.length, kFruits.length, reason: '${sk.name} artwork');
      expect(sprites[0].faces, isNull, reason: '${sk.name} has no separate face layer');
    }
  });
}
