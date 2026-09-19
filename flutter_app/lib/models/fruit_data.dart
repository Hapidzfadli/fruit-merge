/// Port of FRUITS from app.js:5-16. Index in the list IS the fruit level —
/// merge logic, scoring, and collision radius all key off this index.
///
/// The original also carried per-fruit colours and a topper flag, which fed
/// the procedural cartoon fruit drawing. Fruit is now drawn from artwork
/// (see FruitSprites), so appearance — colour, stem, leaves and all — lives
/// in the skin's images and only the name and physical size remain here.
class FruitData {
  final String name;

  /// Diameter in world units; also the diameter of the collision circle.
  final double size;

  const FruitData({required this.name, required this.size});
}

const List<FruitData> kFruits = [
  FruitData(name: 'Cherry', size: 28),
  FruitData(name: 'Strawberry', size: 36),
  FruitData(name: 'Grape', size: 44),
  FruitData(name: 'Orange', size: 54),
  FruitData(name: 'Apple', size: 64),
  FruitData(name: 'Pear', size: 74),
  FruitData(name: 'Peach', size: 84),
  FruitData(name: 'Pineapple', size: 96),
  FruitData(name: 'Melon', size: 108),
  FruitData(name: 'Watermelon', size: 122),
];
