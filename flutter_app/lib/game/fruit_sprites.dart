import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/skin_data.dart';

/// How a fruit should look right now.
enum FruitExpression { normal, warning, mergePop }

/// A skin's face layer: one drawing per mood, shared by every fruit in the set.
///
/// Splitting the face off the fruit means ten bodies and two faces cover all
/// twenty looks, and a change to the eyes is one file rather than ten. It also
/// keeps the expression identical across the set — no fruit ends up with eyes
/// a size bigger than its neighbours.
///
/// Both images are square canvases on the same grid: `tool/cut_face.py`
/// deliberately does not trim them, so swapping one for the other leaves every
/// feature exactly where it was and the change reads as an expression rather
/// than a jump.
class FruitFaces {
  /// Eyes open, small smile — the resting face.
  final ui.Image idle;

  /// X eyes and a worried mouth, for a fruit sitting above the danger line.
  final ui.Image panic;

  const FruitFaces({required this.idle, required this.panic});
}

/// One fruit's artwork plus the measurements that tie it to the physics.
///
/// The art is not a plain square: a stem, leaf or pineapple crown may
/// overhang the fruit's round body. `tool/prepare_skin.py` measures the
/// body — the largest circle that fits inside the art — and records where
/// it sits, so the renderer can line that circle up with the collision
/// circle and let the extras hang outside it.
class FruitSprite {
  final ui.Image image;

  /// Body centre, as a fraction of the image's width/height.
  final double bodyCx;
  final double bodyCy;

  /// Body diameter, as a fraction of the image's width.
  final double bodyScale;

  /// The skin's shared face layer, or null for a skin whose artwork already
  /// has a face painted into it.
  final FruitFaces? faces;

  const FruitSprite({
    required this.image,
    required this.bodyCx,
    required this.bodyCy,
    required this.bodyScale,
    this.faces,
  });

  /// Draws the fruit so its body circle is [size] across and centred on
  /// the current canvas origin. Anything overhanging is drawn outside that
  /// circle, exactly as it sits in the source art.
  void paint(Canvas canvas, double size, {FruitExpression expression = FruitExpression.normal, double opacity = 1.0}) {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final scale = size / (bodyScale * w);
    final dest = Rect.fromLTWH(-bodyCx * w * scale, -bodyCy * h * scale, w * scale, h * scale);

    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (opacity < 1) paint.color = Colors.white.withValues(alpha: opacity);

    switch (expression) {
      case FruitExpression.normal:
        break;
      case FruitExpression.warning:
        // Washed-out and pale — the fruit is "fading away" as its timer runs
        // down. The face layer below is drawn unfiltered, so the X eyes stay
        // dark and legible against the pale body.
        paint.colorFilter = const ColorFilter.matrix(<double>[
          0.55, 0.25, 0.15, 0, 70,
          0.35, 0.45, 0.15, 0, 55,
          0.35, 0.25, 0.35, 0, 55,
          0, 0, 0, 1, 0,
        ]);
        break;
      case FruitExpression.mergePop:
        // A brief bright flash on the fruit that just formed.
        paint.colorFilter = const ColorFilter.matrix(<double>[
          1.15, 0, 0, 0, 26,
          0, 1.15, 0, 0, 26,
          0, 0, 1.15, 0, 26,
          0, 0, 0, 1, 0,
        ]);
        break;
    }

    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, w, h), dest, paint);

    final faceSet = faces;
    if (faceSet == null) return; // face is baked into this skin's artwork

    // The face sheet is drawn to fill the body circle exactly: its features
    // sit centred and span a little over half the canvas, so lining the two
    // squares up lands them on the fruit without a per-fruit offset. Note
    // this box is the *body* circle, not the artwork — a pineapple's crown
    // hangs above it and must not drag the face up with it.
    final face = expression == FruitExpression.warning ? faceSet.panic : faceSet.idle;
    final facePaint = Paint()..filterQuality = FilterQuality.medium;
    if (opacity < 1) facePaint.color = Colors.white.withValues(alpha: opacity);
    canvas.drawImageRect(
      face,
      Rect.fromLTWH(0, 0, face.width.toDouble(), face.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: size, height: size),
      facePaint,
    );
  }
}

/// Loads and holds the fruit artwork for one skin.
///
/// Everything that draws fruit — the board, the next/drop previews, the
/// shop card, the merge guide — goes through this, so the game has a
/// single source of truth for what a fruit looks like.
///
/// Decoded skins are kept in a cache rather than replaced, because the shop
/// has to draw every skin at once to show what each card is selling, not just
/// the one currently equipped.
class FruitSprites {
  final List<FruitSprite> sprites;

  const FruitSprites._(this.sprites);

  static final Map<String, FruitSprites> _cache = {};
  static final Map<String, Future<FruitSprites>> _inFlight = {};
  static String _activeSkin = kDefaultSkinId;

  /// Bumped whenever the equipped skin changes. The game canvas redraws every
  /// frame and picks new artwork up on its own, but widgets showing a fruit
  /// sit still until something tells them to repaint — [FruitImage] listens
  /// to this.
  static final ValueNotifier<int> generation = ValueNotifier<int>(0);

  /// The equipped skin's artwork. Throws if [use] hasn't completed — call it
  /// during app start-up, before any fruit gets drawn.
  static FruitSprites get instance {
    final loaded = _cache[_activeSkin];
    if (loaded == null) {
      throw StateError('FruitSprites.use() must finish before fruit can be drawn');
    }
    return loaded;
  }

  static bool get isLoaded => _cache.containsKey(_activeSkin);

  /// A skin that is already decoded, or null. For callers that would rather
  /// draw nothing this frame than wait — see [FruitImage].
  static FruitSprites? cached(String skin) => _cache[skin];

  FruitSprite operator [](int index) => sprites[index];

  /// Equips [skin], decoding it first if need be.
  static Future<void> use(String skin) async {
    await ensureLoaded(skin);
    if (_activeSkin == skin) return;
    _activeSkin = skin;
    generation.value++;
  }

  /// Decodes [skin] into the cache if it isn't there yet, without equipping
  /// it. Concurrent calls for the same skin share one decode.
  static Future<FruitSprites> ensureLoaded(String skin) {
    final done = _cache[skin];
    if (done != null) return Future.value(done);
    return _inFlight.putIfAbsent(skin, () async {
      try {
        final loaded = await _decodeSkin(skin);
        _cache[skin] = loaded;
        return loaded;
      } finally {
        _inFlight.remove(skin);
      }
    });
  }

  static Future<FruitSprites> _decodeSkin(String skin) async {
    final dir = 'assets/skins/$skin';
    final manifest = jsonDecode(await rootBundle.loadString('$dir/manifest.json')) as Map<String, dynamic>;
    final fruits = (manifest['fruits'] as List).cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

    // A skin either keeps its face on a separate layer or has it painted into
    // each fruit; SkinData says which, so a missing file is a real error here
    // rather than something to shrug off.
    final faces = skinById(skin).layeredFace
        ? FruitFaces(
            idle: await _decode('$dir/face_idle.png'),
            panic: await _decode('$dir/face_x.png'),
          )
        : null;

    final loaded = <FruitSprite>[];
    for (final entry in fruits) {
      loaded.add(FruitSprite(
        image: await _decode('$dir/${entry['file']}'),
        bodyCx: (entry['bodyCx'] as num).toDouble(),
        bodyCy: (entry['bodyCy'] as num).toDouble(),
        bodyScale: (entry['bodyScale'] as num).toDouble(),
        faces: faces,
      ));
    }
    return FruitSprites._(loaded);
  }

  static Future<ui.Image> _decode(String assetKey) async {
    final data = await rootBundle.load(assetKey);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }
}

/// Widget wrapper for the places outside the game canvas that show a
/// fruit: previews, the shop card, the merge guide strip.
class FruitImage extends StatelessWidget {
  final int index;

  /// Diameter of the fruit's body. Overhanging stems/leaves are drawn
  /// outside this box, so leave room above if the art has a topper.
  final double size;
  final FruitExpression expression;

  /// Which skin to draw. Defaults to the equipped one; the shop passes an
  /// explicit id so each card shows the skin it is actually selling rather
  /// than whatever happens to be equipped.
  final String? skin;

  const FruitImage({
    super.key,
    required this.index,
    required this.size,
    this.expression = FruitExpression.normal,
    this.skin,
  });

  @override
  Widget build(BuildContext context) {
    // Rebuild when the equipped skin changes — the game canvas redraws every
    // frame and needs no prompting, but this widget would otherwise keep
    // showing the old artwork.
    return ValueListenableBuilder<int>(
      valueListenable: FruitSprites.generation,
      builder: (context, generation, _) {
        final sprites = skin == null
            ? (FruitSprites.isLoaded ? FruitSprites.instance : null)
            : FruitSprites.cached(skin!);
        if (sprites == null) return SizedBox(width: size, height: size);
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _FruitImagePainter(sprites: sprites, index: index, expression: expression),
          ),
        );
      },
    );
  }
}

class _FruitImagePainter extends CustomPainter {
  final FruitSprites sprites;
  final int index;
  final FruitExpression expression;

  const _FruitImagePainter({required this.sprites, required this.index, required this.expression});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    sprites[index].paint(canvas, size.width, expression: expression);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FruitImagePainter oldDelegate) =>
      !identical(oldDelegate.sprites, sprites) ||
      oldDelegate.index != index ||
      oldDelegate.expression != expression;
}
