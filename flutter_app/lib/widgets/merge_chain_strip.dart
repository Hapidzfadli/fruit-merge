import 'package:flutter/material.dart';
import '../game/fruit_sprites.dart';
import '../models/fruit_data.dart';

/// Horizontal "merge guide" showing the fruit progression from smallest to
/// largest (kFruits[0]..kFruits[9]) — a reference for the player, not part
/// of the original app.js. Purely informational; it doesn't read or affect
/// FruitMergeGame state.
///
/// Each fruit is drawn at a size proportional to its real in-game diameter,
/// so the strip conveys the progression by shape and scale alone and needs
/// no arrows between the fruits.
class MergeChainStrip extends StatelessWidget {
  const MergeChainStrip({super.key});

  /// Display diameters for the smallest and largest fruit. Everything in
  /// between is interpolated from its actual game size, so the strip's
  /// growth curve matches the board's.
  static const double _minDisplay = 14;
  static const double _maxDisplay = 34;

  /// Room above each fruit for stems and the pineapple crown, which the
  /// artwork draws outside the body box.
  static const double _headroom = 14;

  static const double _gap = 4;

  double _displaySize(int index) {
    final smallest = kFruits.first.size;
    final largest = kFruits.last.size;
    final t = (kFruits[index].size - smallest) / (largest - smallest);
    return _minDisplay + t * (_maxDisplay - _minDisplay);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _maxDisplay + _headroom + 14,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      // The row is sized to fit a 300-wide board; scaleDown keeps it tidy on
      // anything narrower instead of letting it overflow or scroll.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < kFruits.length; i++)
              Padding(
                padding: EdgeInsets.only(right: i == kFruits.length - 1 ? 0 : _gap),
                child: SizedBox(
                  width: _displaySize(i),
                  height: _maxDisplay + _headroom,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FruitImage(index: i, size: _displaySize(i)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
