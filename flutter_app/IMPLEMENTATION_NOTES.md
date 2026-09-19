# Offline APK implementation — verified 19 September 2026

Language follow-up: the Flutter interface now consistently uses English, including tutorials, dialogs, fruit and skin names, achievements, and game status messages. Save keys and asset filenames remain unchanged. The stage history below records the original implementation.

## Delivered stages

| Stage | Behavior | Verification |
| --- | --- | --- |
| 1 | Modal pause, Back handling, restart confirmation, background pause, serialized music | Existing suite; final navigation regression and delayed/failed audio-start test |
| 2 | Versioned checkpoints, two-second autosave, Continue, replacement confirmation, run-ID reward deduplication | Moving-body/cooldown round trip, danger timer restoration, corrupted checkpoint isolation, persistence/reload |
| 3 | Top-ten local ranking, Indonesian UI, data information, startup retry, removal of placeholders | Ranking order/ties/cap, menu/settings/results at 320 and 430 logical pixels with 130% text |
| 4 | Zero starting coins/record, preserved legacy balances, nine merge-result collection entries, three one-time rewards, catalog pricing | Legacy migration, insufficient/exact balance, invalid/repeated purchase, reward persistence and deduplication |
| 5 | Three-step tutorial, replay from settings, danger countdown, cooldown status, first-watermelon/record celebration, visual combo | Tutorial/pause/Back/background/Continue flow, confirmed/cancelled restart, results-to-home, status tests |
| 6 | Fixed 60 Hz simulation with two substeps and six-step catch-up limit; injectable seeded randomness; APK build | Equal seeded state at 30/60/120 FPS, hitch/resume handling, existing physics/sprite suite, dense-board benchmark |

Each stage has its own local Git commit. Later regression tests also cover earlier stages. The browser implementation in the repository root was not modified.

## Local data behavior

- Uses the existing `fruitMergeAdventure.save` SharedPreferences key. Checkpoints, progression, completed run IDs, and results are written in the same JSON document through a serial write queue.
- Checkpoint version 1 records score, queue, aim, simulation clock/cooldown, and every living body's position, velocity, rotation, age, danger timer, and flash state. It also retains combo state and whether a watermelon was already made.
- Continue opens paused. Backgrounding, pause, and Home request a save; autosave runs every two seconds during play. A force-close can lose changes since the last successful write. SharedPreferences is local storage, not a cloud backup or a guarantee against storage/device failure.
- Invalid checkpoints are ignored without deleting the existing wallet. Existing coins, skins, and records are kept; legacy records are not fabricated into ranking entries.
- New players start at zero coins and record. Jelly is free; Kawaii costs 250. Match income is floor(score / 10). Achievements give 20/50/100 coins once for the first merge, a 1,000-point match, and first watermelon.
- Collection includes the nine fruits obtainable through merging; cherry is explained as the starting fruit.
- Combo means at least three merges with at most one simulation second between successive merges. It does not multiply score. Danger status takes precedence over celebrations.

## Reproduce checks and build

Run from `flutter_app` with the installed Flutter SDK:

```sh
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --release --no-pub
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`. This is an offline local-testing build using the existing debug signing configuration, not a Play Store release. APK files remain ignored by Git.

## Measurement limits and remaining device checks

- Toolchain used: Flutter 3.47.1 / Dart 3.13.1 on Windows.
- The full automated suite passed 35 tests on 19 September 2026.
- Final `flutter analyze --no-pub`: no issues found.
- Final `flutter build apk --release --no-pub` succeeded on 19 September 2026: 58,628,073 bytes (55.9 MiB), 132.5 seconds for the Gradle build. Output is `build/app/outputs/flutter-apk/app-release.apk`.
- A host-only dense-board run completed 3,600 simulation updates in 773 ms. This measures Dart physics on the development computer, not rendering, Android FPS, thermal behavior, or battery consumption.
- `flutter devices` found only Windows, Chrome, and Edge. `flutter emulators` reported no emulators available.
- Android startup time, audible music/SFX, physical vibration, and a 15-minute Android play session have **not been measured**. Widget tests mock native audio; the queue test validates ordering and failure recovery, not sound output.
- Device acceptance: install the APK; play for 15 minutes; create a dense pile; test repeated background/resume, Back, restart, Home/Continue, and force-close/reopen; check audio toggles, tutorial, saved progress, and absence of crashes or clipped fruit.
- No backend, ads SDK, cloud ranking, new signing key, or store publication was added.
