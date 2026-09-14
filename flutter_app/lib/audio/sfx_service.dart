import 'package:audioplayers/audioplayers.dart';
import '../state/app_state.dart';

/// Port of the SFX wrapper + startMusic/stopMusic from audio.js, using
/// pre-baked WAV assets (see scratchpad/gen_sfx.py) instead of realtime
/// Web Audio oscillator synthesis — see the migration plan's Fase 3 note
/// on why (asset-based audio is lighter and more reliable on low-end
/// mobile hardware than runtime synthesis).
///
/// Mirrors the `Sfx`/`doVibrate` gating pattern from app.js:79-86: every
/// play call checks AppState.sfx/music first, so callers don't need to.
class SfxService {
  final AppState appState;

  // A small round-robin pool so overlapping sounds (e.g. a fast merge
  // chain) can play concurrently instead of cutting each other off.
  final List<AudioPlayer> _pool = List.generate(4, (i) => AudioPlayer(playerId: 'sfx_pool_$i'));
  int _poolIndex = 0;

  AudioPlayer? _musicPlayer;
  Future<void> _musicQueue = Future.value();

  Future<void> _enqueue(Future<void> Function() action) {
    _musicQueue = _musicQueue.then((_) => action()).catchError((Object _) {});
    return _musicQueue;
  }

  SfxService(this.appState) {
    for (final p in _pool) {
      p.setPlayerMode(PlayerMode.lowLatency);
      p.setReleaseMode(ReleaseMode.stop);
    }
  }

  Future<void> _play(String assetPath) async {
    if (!appState.sfx) return;
    final player = _pool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _pool.length;
    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Best-effort: a dropped SFX should never crash gameplay.
    }
  }

  /// audio.js SFX.drop() — app.js dropFruit() call site.
  void drop() => _play('sfx/drop.wav');

  /// audio.js SFX.merge(index) — app.js mergeBodies() call site.
  /// [level] is the resulting fruit's index (1-9, since level 0 can never
  /// be a merge result — mirrors FRUITS/MERGE_SCORE indexing).
  void merge(int level) => _play('sfx/merge_${level.clamp(1, 9)}.wav');

  /// audio.js SFX.gameOver() — app.js gameOver() call site.
  void gameOver() => _play('sfx/game_over.wav');

  /// audio.js SFX.click() — used by nearly every button tap.
  void click() => _play('sfx/click.wav');

  /// audio.js SFX.buy() — app.js shop purchase call site.
  void buy() => _play('sfx/buy.wav');

  /// Port of startMusic() (audio.js:44-69). The original loops 4 notes via
  /// setInterval; here the whole loop is one asset played with
  /// ReleaseMode.loop, which is equivalent and cheaper.
  Future<void> startMusic() => _enqueue(() async {
    if (!appState.music) return;
    if (_musicPlayer != null) return; // matches "if (musicNodes) return;" no-op guard
    final player = AudioPlayer(playerId: 'music');
    _musicPlayer = player;
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(1.0); // gain is already baked into loop.wav's envelope
    await player.play(AssetSource('music/loop.wav'));
  });

  Future<void> stopMusic() => _enqueue(() async {
    final player = _musicPlayer;
    if (player == null) return;
    _musicPlayer = null;
    try { await player.stop(); } finally { await player.dispose(); }
  });

  Future<void> dispose() async {
    await stopMusic();
    for (final p in _pool) {
      await p.dispose();
    }
  }
}
