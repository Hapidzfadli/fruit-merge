import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/sfx_service.dart';
import '../state/app_state.dart';
import '../widgets/app_back_button.dart';
import 'theme.dart';
import 'tutorial_dialog.dart';

/// Port of buildSettingsScreen() (app.js:432-468).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final sfx = context.read<SfxService>();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F1), // .screen-flat, style.css:83
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppBackButton(
                    onTap: () {
                      sfx.click();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Ordering intentionally mirrors app.js:444-446: Music/Vibration
              // click-then-toggle, but SFX toggles BEFORE clicking — so
              // muting SFX plays no confirmation click, unmuting does.
              _SettingsRow(
                label: 'Music',
                value: appState.music,
                onToggle: () {
                  sfx.click();
                  appState.toggleMusic();
                },
              ),
              _SettingsRow(
                label: 'Sound Effects',
                value: appState.sfx,
                onToggle: () {
                  appState.toggleSfx();
                  sfx.click();
                },
              ),
              _SettingsRow(
                label: 'Vibration',
                value: appState.vibration,
                onToggle: () {
                  sfx.click();
                  appState.toggleVibration();
                },
              ),
              const SizedBox(height: 26),
              SecondaryButton(
                label: 'How to Play',
                onPressed: () => showTutorial(context),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Data & Storage',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Data & Storage'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'Scores, coins, skins, settings, and saved games are stored on this device. This game has no accounts or server sync. Clearing app data may erase your progress. After a force-close, your game resumes from the last autosave.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onToggle;

  const _SettingsRow({
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ToggleSwitch(value: value, onToggle: onToggle),
        ],
      ),
    );
  }
}
