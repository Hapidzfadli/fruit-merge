import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/game/fruit_merge_game.dart';
import 'package:flutter_app/models/run_snapshot.dart';
import 'package:flutter_app/state/app_state.dart';

FruitMergeGame game() => FruitMergeGame(onScore: (_) {}, onMerge: (_) {}, onDrop: () {}, onGameOver: () {}, onScorePop: (_, _) {});
void main() {
  test('moving board and cooldown round trip; invalid checkpoint rejected', () {
    final a = game()..dropFruit()..update(1/60);
    final snapshot = a.snapshot('run', 40);
    final b = game()..restore(RunSnapshot.parse(snapshot.data)!);
    expect(b.snapshot('run', 40).data, snapshot.data);
    expect(RunSnapshot.parse({...snapshot.data, 'current': 99}), isNull);
  });
  test('checkpoint persists and completed run awards only once', () async {
    SharedPreferences.setMockInitialValues({});
    final a = AppState();
    await a.saveRun(game().snapshot('run', 100));
    final b = AppState(); await b.load();
    expect(b.activeRun!.score, 100);
    b.addScore(100);
    expect(b.recordGameOver(runId: 'run'), 10);
    expect(b.recordGameOver(runId: 'run'), 0);
    await b.persist();
    final c = AppState(); await c.load();
    expect(c.activeRun, isNull);
  });
}
