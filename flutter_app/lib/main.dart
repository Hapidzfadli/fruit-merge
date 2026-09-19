import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio/sfx_service.dart';
import 'game/fruit_sprites.dart';
import 'state/app_state.dart';
import 'ui/menu_page.dart';

void main() {
  runApp(const FruitMergeApp());
}

class FruitMergeApp extends StatefulWidget {
  const FruitMergeApp({super.key});

  @override
  State<FruitMergeApp> createState() => _FruitMergeAppState();
}

class _FruitMergeAppState extends State<FruitMergeApp> {
  final AppState _appState = AppState();
  late final SfxService _sfx;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _sfx = SfxService(_appState);
    _loadFuture = _boot();
  }

  /// Fruit artwork has to be decoded before anything draws a fruit, so it is
  /// part of the same start-up gate as the saved game state — and it has to
  /// come second, because which skin to decode is itself part of the save.
  Future<void> _boot() async {
    await _appState.load();
    await FruitSprites.use(_appState.equippedSkin);
  }

  @override
  void dispose() {
    _sfx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appState),
        Provider.value(value: _sfx),
      ],
      child: MaterialApp(
        title: 'Fruit Merge Adventure',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFFF9F1C),
        ),
        home: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Game belum berhasil dimuat.'),
                      TextButton(
                        onPressed: () => setState(() => _loadFuture = _boot()),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              // Deliberately not an animated spinner: start-up is brief, and
              // a never-ending animation would keep the widget tree from
              // ever settling for tests that boot the app.
              return const Scaffold(
                backgroundColor: Color(0xFFFFF6EA),
                body: Center(
                  child: Text(
                    'Fruit Merge',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B4A),
                    ),
                  ),
                ),
              );
            }
            return const MenuPage();
          },
        ),
      ),
    );
  }
}
