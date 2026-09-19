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
      appBar: AppBar(title: const Text('Collection & Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${state.collection.length}/9 merged fruits discovered',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(
            'Cherry is the starting fruit. Merge fruits to discover the rest of the collection.',
          ),
          for (var i = 1; i < kFruits.length; i++)
            ListTile(
              leading: state.collection.contains(i)
                  ? FruitImage(index: i, size: 32)
                  : const Icon(Icons.lock_outline),
              title: Text(kFruits[i].name),
              subtitle: Text(
                state.collection.contains(i) ? 'Discovered' : 'Not discovered yet',
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
                    ? 'Completed • reward claimed'
                    : '+${AppState.achievementRewards[entry.key]} coins',
              ),
            ),
        ],
      ),
    );
  }
}
