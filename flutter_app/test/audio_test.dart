import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/audio/sfx_service.dart';
import 'package:flutter_app/state/app_state.dart';

import 'audio_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'music stop waits for pending start and queue survives native failure',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final events = <String>[];
      mockAudioChannels(
        beforeCall: (call) async {
          if ((call.arguments as Map?)?['playerId'] != 'music') return;
          events.add(call.method);
          if (call.method == 'setVolume') {
            entered.complete();
            await release.future;
            throw PlatformException(code: 'test_audio_unavailable');
          }
        },
      );
      final state = AppState();
      final sfx = SfxService(state);
      final start = sfx.startMusic();
      final stop = sfx.stopMusic();
      await entered.future;
      expect(events, isNot(contains('stop')));
      release.complete();
      await Future.wait([start, stop]);
      expect(events, contains('stop'));
      expect(events, contains('dispose'));
      final count = events.length;
      state.music = false;
      await sfx.startMusic();
      expect(events.length, count);
      await sfx.dispose();
    },
  );
}
