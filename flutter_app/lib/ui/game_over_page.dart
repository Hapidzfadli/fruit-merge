import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/sfx_service.dart';
import '../state/app_state.dart';
import '../game/fruit_sprites.dart';
import 'theme.dart';

/// Port of buildGameOverScreen() (app.js:293-346), extended with a frozen
/// snapshot of the board at the moment of game over (not in the original —
/// added per user request, mirroring reference screenshots of similar
/// merge games that show the final pile behind the score).
/// [score] and [earned] are passed in from the run that just ended — by the
/// time this page shows, AppState.recordGameOver() has already updated
/// highScore/coins (app.js:654-667), so `context.watch<AppState>().highScore`
/// reflects the post-game-over value.
class GameOverPage extends StatelessWidget {
  final int score;
  final int earned;
  final Uint8List? boardSnapshot;
  final bool newRecord;

  const GameOverPage({
    super.key,
    required this.score,
    required this.earned,
    this.boardSnapshot,
    this.newRecord = false,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kScreenGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
            child: Column(
              children: [
                const Text(
                  'Permainan Selesai',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(height: 22),
                if (newRecord)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Rekor baru! 🏆',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _StatCard(label: 'Skor', value: '$score'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _StatCard(
                        label: 'Rekor',
                        value: '${appState.highScore}',
                      ),
                    ),
                  ],
                ),
                if (earned > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '+$earned koin diperoleh',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A6D1A),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Expanded(child: _BoardSnapshot(bytes: boardSnapshot)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Main Lagi',
                        fontSize: 15,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: () {
                          context.read<SfxService>().click();
                          Navigator.of(context)
                              .pop(true); // signal caller to restart
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        label: 'Beranda',
                        onPressed: () {
                          context.read<SfxService>().click();
                          Navigator.of(context).pop(false);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AppColors.label,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Frozen board screenshot captured by GamePage right as game over
/// triggered (see GamePage._captureBoardSnapshot). Falls back to the
/// decorative falling-fruit strip if the capture failed for some reason.
class _BoardSnapshot extends StatelessWidget {
  final Uint8List? bytes;
  const _BoardSnapshot({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    if (data == null) return const _FallStrip();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        border: Border.all(color: const Color(0xFFE8B98A), width: 8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(data, fit: BoxFit.contain),
      ),
    );
  }
}

/// Port of the falling-fruit decorative strip (app.js:296-308). A static
/// (non-looping) arrangement for now — the original animates each fruit
/// falling on an infinite loop via CSS keyframes.
class _FallStrip extends StatelessWidget {
  const _FallStrip();

  @override
  Widget build(BuildContext context) {
    const drops = [
      (left: 0.15, size: 26.0, fruit: 0),
      (left: 0.35, size: 30.0, fruit: 2),
      (left: 0.55, size: 24.0, fruit: 3),
      (left: 0.75, size: 28.0, fruit: 4),
    ];
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: drops
              .map(
                (d) => Positioned(
                  left: constraints.maxWidth * d.left,
                  top: 20, // leaves room for stems drawn above the body box
                  child: FruitImage(index: d.fruit, size: d.size),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
