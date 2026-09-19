import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests have no native audio plugin. Keep its method/event setup local.
void mockAudioChannels({Future<void> Function(MethodCall)? beforeCall}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
  }
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      await beforeCall?.call(call);
      if (call.method == 'create') {
        final id = (call.arguments as Map)['playerId'];
        messenger.setMockMethodCallHandler(
          MethodChannel('xyz.luan/audioplayers/events/$id'),
          (_) async => null,
        );
      }
      return null;
    },
  );
}
