/// Cosmetic fruit sets. Descended from SKINS in app.js:18-23, but where
/// the original recoloured a procedurally drawn cartoon fruit, a skin is
/// now a folder of artwork under `assets/skins/<id>/` prepared by
/// `tool/prepare_skin.py` and loaded through FruitSprites.
class SkinData {
  final String id;
  final String name;
  final int price;

  /// Whether the artwork keeps its face on a separate layer — `face_idle.png`
  /// and `face_x.png`, cut by `tool/cut_face.py` — instead of painting it into
  /// each fruit. Only a layered skin can pull a face when one of its fruits
  /// drifts above the danger line; the rest just fade.
  final bool layeredFace;

  const SkinData({
    required this.id,
    required this.name,
    required this.price,
    this.layeredFace = false,
  });
}

/// The skin every player starts with. Adding another means running the
/// prepare script for it, listing its folder in pubspec.yaml, and adding an
/// entry here.
const String kDefaultSkinId = 'gummy';

const List<SkinData> kSkins = [
  // Splits the face off the fruit — ten plain bodies plus face_idle/face_x,
  // composited at draw time — so a fruit stuck above the danger line actually
  // changes expression instead of only fading.
  SkinData(id: kDefaultSkinId, name: 'Jelly Candy', price: 0, layeredFace: true),
  // The original artwork, with a cheerful face painted into every fruit.
  // Priced to match the first paid tier in app.js, which a player can afford
  // partway into their first few runs.
  SkinData(id: 'kawaii_real', name: 'Kawaii Fruits', price: 250),
];

SkinData skinById(String id) => kSkins.firstWhere((s) => s.id == id, orElse: () => kSkins.first);
