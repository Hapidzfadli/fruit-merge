import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skin_data.dart';
import '../models/run_snapshot.dart';

/// Port of the `state` object + loadSave()/persist() from app.js:36-77.
///
/// Screen/navigation is intentionally NOT part of this class — that's
/// handled by Flutter's Navigator + Flame overlays (see the architecture
/// table in the migration plan), unlike app.js where `state.screen` drove
/// DOM visibility toggling.
///
/// currentIndex/nextIndex/dropX (per-run drop queue state) are also not
/// here — they belong to the Flame game instance, not persisted app state.
class AppState extends ChangeNotifier {
  static const _saveKey = 'fruitMergeAdventure.save';

  int score = 0;
  int highScore = 0;
  int coins = 0;
  String equippedSkin = kDefaultSkinId;
  List<String> ownedSkins = [kDefaultSkinId];
  bool music = true;
  bool sfx = true;
  bool vibration = true;
  bool tutorialSeen = false;
  RunSnapshot? activeRun;
  List<String> completedRuns = [];
  List<Map<String, dynamic>> ranking = [];
  Set<int> collection = {};
  Set<String> achievements = {};
  static const achievementRewards = {
    'merge': 20,
    'score1000': 50,
    'watermelon': 100,
  };
  static const achievementNames = {
    'merge': 'Merge pertama',
    'score1000': '1.000 poin dalam satu permainan',
    'watermelon': 'Semangka pertama',
  };

  void _award(String id) {
    if (achievements.add(id)) coins += achievementRewards[id]!;
  }

  void recordMerge(int level) {
    if (level < 1 || level > 9) return;
    collection.add(level);
    _award('merge');
    if (score >= 1000) _award('score1000');
    if (level == 9) _award('watermelon');
    persist();
    notifyListeners();
  }

  Future<void> _writes = Future.value();

  Future<void> saveRun(RunSnapshot snapshot) {
    if (completedRuns.contains(snapshot.id)) return Future.value();
    activeRun = snapshot;
    notifyListeners();
    return persist();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) {
      return; // keep defaults, matching loadSave()'s catch branch
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      highScore = (data['highScore'] as num?)?.toInt() ?? 0;
      coins = data['coins'] != null ? (data['coins'] as num).toInt() : 0;
      // Saves written before the artwork skins landed name skins that no
      // longer exist ('classic', 'crystal', ...), so anything unrecognised
      // is dropped rather than leaving the player with a missing skin.
      final knownIds = kSkins.map((s) => s.id).toSet();
      final savedSkin = data['equippedSkin'] as String?;
      equippedSkin = knownIds.contains(savedSkin) ? savedSkin! : kDefaultSkinId;
      final owned = (data['ownedSkins'] as List?)
          ?.cast<String>()
          .where(knownIds.contains)
          .toList();
      ownedSkins = (owned != null && owned.isNotEmpty)
          ? owned
          : [kDefaultSkinId];
      if (!ownedSkins.contains(kDefaultSkinId)) ownedSkins.add(kDefaultSkinId);
      music = data['music'] != false;
      sfx = data['sfx'] != false;
      vibration = data['vibration'] != false;
      tutorialSeen = data['tutorialSeen'] == true;
      collection = (data['collection'] as List? ?? [])
          .whereType<int>()
          .where((i) => i >= 1 && i <= 9)
          .toSet();
      achievements = (data['achievements'] as List? ?? [])
          .whereType<String>()
          .where(achievementRewards.containsKey)
          .toSet();
      activeRun = RunSnapshot.parse(data['activeRun']);
      completedRuns = (data['completedRuns'] as List? ?? [])
          .whereType<String>()
          .toList();
      ranking = (data['ranking'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where(
            (e) =>
                e['score'] is int &&
                e['level'] is int &&
                (e['level'] as int) >= 0 &&
                (e['level'] as int) < 10 &&
                e['date'] is String &&
                DateTime.tryParse(e['date'] as String) != null,
          )
          .take(10)
          .toList();
      if (activeRun != null && completedRuns.contains(activeRun!.id)) {
        activeRun = null;
      }
      notifyListeners();
    } catch (_) {
      // corrupt save data — keep defaults, same fallback behavior as loadSave()
    }
  }

  Future<void> persist() {
    final encoded = jsonEncode({
      'highScore': highScore,
      'coins': coins,
      'equippedSkin': equippedSkin,
      'ownedSkins': ownedSkins,
      'music': music,
      'sfx': sfx,
      'vibration': vibration,
      'tutorialSeen': tutorialSeen,
      'activeRun': activeRun?.data,
      'completedRuns': completedRuns,
      'ranking': ranking,
      'collection': collection.toList(),
      'achievements': achievements.toList(),
    });
    final write = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_saveKey, encoded)) {
        throw StateError('Save failed');
      }
    });
    _writes = write.catchError((Object _) {});
    return write;
  }

  void addScore(int amount) {
    score += amount;
    notifyListeners();
  }

  void resetScore() {
    score = 0;
    notifyListeners();
  }

  /// Port of gameOver() coin/highscore bookkeeping (app.js:654-667), minus
  /// the SFX/vibration/navigation side effects which live in the UI layer.
  /// Returns the coins earned this run.
  int recordGameOver({String? runId, int highestLevel = 0}) {
    if (runId != null && completedRuns.contains(runId)) return 0;
    if (runId != null) completedRuns.add(runId);
    activeRun = null;
    ranking.add({
      'score': score,
      'level': highestLevel,
      'order': completedRuns.length,
      'date': DateTime.now().toUtc().toIso8601String(),
    });
    ranking.sort((a, b) {
      final scores = (b['score'] as int).compareTo(a['score'] as int);
      if (scores != 0) return scores;
      final dates = (b['date'] as String).compareTo(a['date'] as String);
      return dates != 0
          ? dates
          : ((b['order'] as int?) ?? 0).compareTo((a['order'] as int?) ?? 0);
    });
    ranking = ranking.take(10).toList();
    if (score > highScore) highScore = score;
    final earned = score ~/ 10;
    coins += earned;
    persist();
    notifyListeners();
    return earned;
  }

  bool buySkin(String skinId) {
    final skins = kSkins.where((skin) => skin.id == skinId);
    if (skins.isEmpty) return false;
    final price = skins.first.price;
    if (ownedSkins.contains(skinId) || coins < price) return false;
    coins -= price;
    ownedSkins.add(skinId);
    equippedSkin = skinId;
    persist();
    notifyListeners();
    return true;
  }

  void equipSkin(String skinId) {
    if (!ownedSkins.contains(skinId)) return;
    equippedSkin = skinId;
    persist();
    notifyListeners();
  }

  void toggleMusic() {
    music = !music;
    persist();
    notifyListeners();
  }

  void toggleSfx() {
    sfx = !sfx;
    persist();
    notifyListeners();
  }

  void toggleVibration() {
    vibration = !vibration;
    persist();
    notifyListeners();
  }
}
