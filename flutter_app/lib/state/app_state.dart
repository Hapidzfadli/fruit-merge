import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skin_data.dart';

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
  int highScore = 1280;
  int coins = 340;
  String equippedSkin = kDefaultSkinId;
  List<String> ownedSkins = [kDefaultSkinId];
  bool music = true;
  bool sfx = true;
  bool vibration = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) return; // keep defaults, matching loadSave()'s catch branch
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      highScore = (data['highScore'] as num?)?.toInt() ?? 0;
      coins = data['coins'] != null ? (data['coins'] as num).toInt() : 340;
      // Saves written before the artwork skins landed name skins that no
      // longer exist ('classic', 'crystal', ...), so anything unrecognised
      // is dropped rather than leaving the player with a missing skin.
      final knownIds = kSkins.map((s) => s.id).toSet();
      final savedSkin = data['equippedSkin'] as String?;
      equippedSkin = knownIds.contains(savedSkin) ? savedSkin! : kDefaultSkinId;
      final owned = (data['ownedSkins'] as List?)?.cast<String>().where(knownIds.contains).toList();
      ownedSkins = (owned != null && owned.isNotEmpty) ? owned : [kDefaultSkinId];
      if (!ownedSkins.contains(kDefaultSkinId)) ownedSkins.add(kDefaultSkinId);
      music = data['music'] != false;
      sfx = data['sfx'] != false;
      vibration = data['vibration'] != false;
      notifyListeners();
    } catch (_) {
      // corrupt save data — keep defaults, same fallback behavior as loadSave()
    }
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode({
      'highScore': highScore,
      'coins': coins,
      'equippedSkin': equippedSkin,
      'ownedSkins': ownedSkins,
      'music': music,
      'sfx': sfx,
      'vibration': vibration,
    }));
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
  int recordGameOver() {
    if (score > highScore) highScore = score;
    final earned = score ~/ 10;
    coins += earned;
    persist();
    notifyListeners();
    return earned;
  }

  bool buySkin(String skinId, int price) {
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
