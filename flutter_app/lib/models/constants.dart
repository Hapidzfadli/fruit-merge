/// Port of the global constants from app.js:25-34.
/// These are in the same "board units" as the original — FruitMergeGame
/// uses them directly as its world-space pixel dimensions (see the custom
/// pure-Dart physics note in fruit_merge_game.dart for why it's not
/// Forge2D's meter-based units).
class GameConstants {
  static const double boardWidth = 300;
  static const double boardHeight = 460;
  static const double wall = 8;
  static const double pw = boardWidth - wall * 2;
  static const double ph = boardHeight - wall;
  static const double lineY = 40;

  /// Radius of the board's rounded bottom corners, in world units. Shared
  /// by the physics boundary (FruitMergeGame) and the visual frame/clip
  /// (GamePage) so a fruit resting in a corner is never drawn clipped by a
  /// curve the simulation doesn't know about.
  static const double cornerRadius = 22;

  /// mergeScore[i] = score awarded for producing fruit level i via merge.
  /// Index 0 is a placeholder (level 0 can never be a merge result).
  static const List<int> mergeScore = [0, 20, 40, 70, 110, 160, 230, 320, 440, 600];

  static const double spawnAnimMs = 300;

  /// Time a settled fruit can sit above [lineY] before triggering game
  /// over. Extended from the original app.js value (1000ms, logic.md §8.4)
  /// to 2900ms to make room for the warning state (color/eyes change, see
  /// FruitMergeGame._drawFruit) to actually be visible/legible.
  static const double overLimitMs = 2900;
  static const double dropCooldownMs = 320;
}
