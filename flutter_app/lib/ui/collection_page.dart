import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/fruit_data.dart';
import '../game/fruit_sprites.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Koleksi & Pencapaian')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${state.collection.length}/9 buah hasil merge ditemukan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(
            'Ceri adalah buah awal. Buat buah lainnya melalui merge untuk melengkapi koleksi.',
          ),
          for (var i = 1; i < kFruits.length; i++)
            ListTile(
              leading: state.collection.contains(i)
                  ? FruitImage(index: i, size: 32)
                  : const Icon(Icons.lock_outline),
              title: Text(kFruits[i].name),
              subtitle: Text(
                state.collection.contains(i) ? 'Ditemukan' : 'Belum ditemukan',
              ),
            ),
          const Divider(),
          for (final entry in AppState.achievementNames.entries)
            ListTile(
              leading: Icon(
                state.achievements.contains(entry.key)
                    ? Icons.check_circle
                    : Icons.emoji_events_outlined,
              ),
              title: Text(entry.value),
              subtitle: Text(
                state.achievements.contains(entry.key)
                    ? 'Selesai • hadiah sudah diterima'
                    : '+${AppState.achievementRewards[entry.key]} koin',
              ),
            ),
        ],
      ),
    );
  }
}
