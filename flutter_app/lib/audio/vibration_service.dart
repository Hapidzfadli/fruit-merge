import 'package:vibration/vibration.dart';
import '../state/app_state.dart';

/// Port of doVibrate() (app.js:86), which wraps navigator.vibrate(). Kept
/// separate from SfxService because the original wires vibration into only
/// a few specific call sites (merge, gameOver, buy) — not every SFX.
Future<void> doVibrate(AppState appState, int ms) async {
  if (!appState.vibration) return;
  try {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) await Vibration.vibrate(duration: ms);
  } catch (_) {
    // Best-effort: platforms without a vibrator (web, desktop) no-op.
  }
}
