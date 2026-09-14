import 'dart:typed_data';
import 'dart:async';
import '../models/run_snapshot.dart';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../audio/sfx_service.dart';
import '../audio/vibration_service.dart';
import '../game/fruit_merge_game.dart';
import '../game/fruit_sprites.dart';
import '../models/constants.dart';
import '../state/app_state.dart';
import '../widgets/merge_chain_strip.dart';
import 'theme.dart';
import 'game_over_page.dart';

/// Port of buildGameScreen() + the physics/game-loop wiring in app.js
/// (§7 Game, §8 Physics, §9 Drop control). Hosts the FruitMergeGame board
/// plus the surrounding topbar/pause-overlay chrome that used to be plain
/// DOM around the Matter.js canvas.
class GamePage extends StatefulWidget {
  final RunSnapshot? savedRun;
  const GamePage({super.key, this.savedRun});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _ScorePop {
  final int id;
  final Offset screenPos;
  final int amount;
  _ScorePop(this.id, this.screenPos, this.amount);
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final FruitMergeGame _game;
  late final AppState _appState;
  late final SfxService _sfx;
  bool _paused = false;
  bool _ending = false;
  bool _leaving = false;
  late String _runId;
  Timer? _autosave;
  String? _lastSave;

  Future<void> _save() async {
    if (_ending) return;
    final snapshot = _game.snapshot(_runId, _appState.score);
    final signature = snapshot.data.toString();
    if (signature == _lastSave) return;
    try {
      await _appState.saveRun(snapshot);
      _lastSave = signature;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penyimpanan gagal. Coba lagi.')));
    }
  }
  final List<_ScorePop> _pops = [];
  int _popId = 0;
  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appState = context.read<AppState>();
    _sfx = context.read<SfxService>();
    _runId = widget.savedRun?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _game = FruitMergeGame(
      onScore: (amount) => _appState.addScore(amount),
      onMerge: (level) {
        _sfx.merge(level);
        doVibrate(_appState, 15);
      },
      onDrop: _sfx.drop,
      onGameOver: _handleGameOver,
      onScorePop: (worldPos, amount) {
        final id = _popId++;
        final pop = _ScorePop(id, _game.worldToScreen(worldPos), amount);
        setState(() => _pops.add(pop));
        Future.delayed(const Duration(milliseconds: 750), () {
          if (mounted) setState(() => _pops.removeWhere((p) => p.id == id));
        });
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _appState.resetScore();
      if (widget.savedRun != null) {
        _game.restore(widget.savedRun!);
        _appState.addScore(widget.savedRun!.score);
        _openPause();
      }
      _autosave = Timer.periodic(const Duration(seconds: 2), (_) { if (!_paused) _save(); });
      _save();
      if (_paused) return;
      if (_appState.music) _sfx.startMusic(); // app.js startGame(): if (state.music) startMusic()
    });
  }

  @override
  void dispose() {
    _autosave?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _sfx.stopMusic();
    super.dispose();
  }

  // Port of the visibilitychange handler (app.js:751-753): backgrounding
  // the app while playing should pause, same as tapping the pause button.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_paused && state != AppLifecycleState.resumed) _openPause();
  }

  /// Freezes the board's last visual state so GameOverPage can show it
  /// behind the score card — physics already stopped updating the instant
  /// FruitMergeGame set gameOverFired, so the very next frame is that
  /// frozen state; wait for it to actually render before capturing.
  Future<Uint8List?> _captureBoardSnapshot() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _boardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null; // best-effort — GameOverPage just falls back to no snapshot
    }
  }

  Future<void> _handleGameOver() async {
    if (_ending || !mounted) return;
    _ending = true;
    _sfx.gameOver();
    doVibrate(_appState, 60);
    await _sfx.stopMusic(); // app.js gameOver(): stopMusic()
    final snapshot = await _captureBoardSnapshot();
    final score = _appState.score;
    final earned = _appState.recordGameOver(runId: _runId);
    if (!mounted) return;
    final again = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GameOverPage(score: score, earned: earned, boardSnapshot: snapshot)),
    );
    if (!mounted) return;
    if (again == true) {
      _ending = false;
      _runId = DateTime.now().microsecondsSinceEpoch.toString();
      _appState.resetScore();
      _game.resetBoard();
      _game.resumeEngine();
      if (_appState.music) _sfx.startMusic();
    } else {
      setState(() => _leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _openPause() async {
    if (!mounted || _paused || _ending || _leaving) return;
    _sfx.click();
    setState(() => _paused = true);
    _game.pauseEngine();
    _save();
    _sfx.stopMusic(); // app.js pauseGame(): stopMusic()
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x801E140F),
      builder: (_) => _PauseDialog(
        appState: _appState,
        sfx: _sfx,
        onResume: () {
          Navigator.of(context).pop('resume');
        },
        onRestart: () async {
          final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
            title: const Text('Mulai ulang?'),
            content: const Text('Pertandingan ini akan diganti dengan permainan baru.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Mulai ulang')),
            ],
          ));
          if (confirmed == true && mounted) Navigator.of(context).pop('restart');
        },
        onHome: () {
          Navigator.of(context).pop('home');
        },
      ),
    );
    if (!mounted) return;
    if (action == 'home') {
      await _save();
      if (!mounted) return;
      setState(() => _leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    if (action == 'restart') {
      _runId = DateTime.now().microsecondsSinceEpoch.toString();
      _appState.resetScore();
      _game.resetBoard();
      await _save();
      if (!mounted) return;
    }
    setState(() => _paused = false);
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      _openPause();
      return;
    }
    _game.resumeEngine();
    if (_appState.music) _sfx.startMusic();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, result) { if (!didPop) _openPause(); },
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kScreenGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _openPause,
                        child: const SizedBox(width: 44, height: 44, child: Icon(Icons.pause_rounded, color: AppColors.text)),
                      ),
                    ),
                    _Pill(label: 'Score', value: '${appState.score}'),
                    ValueListenableBuilder<int>(
                      valueListenable: _game.nextIndexNotifier,
                      builder: (context, nextIndex, _) => _NextPreview(index: nextIndex),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: GameConstants.pw / GameConstants.ph,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: GameConstants.boardWidth),
                        child: RepaintBoundary(
                          key: _boardKey,
                          child: LayoutBuilder(
                            builder: (context, boardConstraints) {
                              // The board scales down on small screens, so derive
                              // the corner radii from the world-space constant the
                              // physics uses. A fixed pixel radius would drift out
                              // of step with the simulated boundary and clip fruit
                              // resting in the corners.
                              const borderWidth = 8.0;
                              // The game canvas sits inside the border, so it's the
                              // inner width that maps onto the pw-wide world.
                              final scale = (boardConstraints.maxWidth - borderWidth * 2) / GameConstants.pw;
                              final innerRadius = GameConstants.cornerRadius * scale;
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      border: Border.all(color: const Color(0xFFE8B98A), width: borderWidth),
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(innerRadius + borderWidth),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(innerRadius)),
                                      // MouseRegion catches real hover (desktop/web mouse
                                      // moving with no button down) so the drop preview
                                      // tracks the cursor even before a click — Flame's
                                      // own gesture callbacks only fire on an active
                                      // pointer (touch/drag), not passive hover.
                                      child: MouseRegion(
                                        onHover: (event) => _game.updateAimFromScreen(event.localPosition),
                                        child: GameWidget(game: _game),
                                      ),
                                    ),
                                  ),
                                  for (final pop in _pops) _ScorePopWidget(pop: pop),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const MergeChainStrip(),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class _ScorePopWidget extends StatelessWidget {
  final _ScorePop pop;
  const _ScorePopWidget({required this.pop});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: pop.screenPos.dx,
      top: pop.screenPos.dy,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: 1 - t,
            child: Transform.translate(offset: Offset(0, -34 * t), child: child),
          ),
          child: Text(
            '+${pop.amount}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.coral, fontSize: 14, shadows: [Shadow(color: Colors.white, blurRadius: 0, offset: Offset(0, 1))]),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.label)),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _NextPreview extends StatelessWidget {
  final int index;
  const _NextPreview({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('NEXT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.label)),
          const SizedBox(height: 4),
          // Extra height below the label so a stem or crown, which the art
          // draws above the fruit's body box, still has room.
          SizedBox(
            height: 40,
            child: Align(alignment: Alignment.bottomCenter, child: FruitImage(index: index, size: 30)),
          ),
        ],
      ),
    );
  }
}

/// Port of buildPauseOverlay() (app.js:261-290).
class _PauseDialog extends StatelessWidget {
  final AppState appState;
  final SfxService sfx;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const _PauseDialog({
    required this.appState,
    required this.sfx,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paused', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 14),
            PrimaryButton(label: 'Resume', onPressed: () {
              sfx.click();
              onResume();
            }),
            const SizedBox(height: 12),
            SecondaryButton(label: 'Restart', onPressed: () {
              sfx.click();
              onRestart();
            }),
            const SizedBox(height: 12),
            SecondaryButton(label: 'Home', onPressed: () {
              sfx.click();
              onHome();
            }),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: appState,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sound', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  ToggleSwitch(value: appState.music, onToggle: () {
                    sfx.click();
                    appState.toggleMusic();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
