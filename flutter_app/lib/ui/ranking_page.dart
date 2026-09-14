import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/fruit_data.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});
  @override
  Widget build(BuildContext context) {
    final entries = context.watch<AppState>().ranking;
    return Scaffold(appBar: AppBar(title: const Text('Ranking Lokal')),
      body: entries.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada hasil. Selesaikan pertandingan pertamamu!', textAlign: TextAlign.center))) :
      ListView.builder(itemCount: entries.length, itemBuilder: (_, i) {
        final e = entries[i];
        final date = DateTime.parse(e['date'] as String).toLocal();
        return ListTile(leading: Text('${i + 1}'), title: Text('${e['score']} poin'),
          subtitle: Text('${date.day}/${date.month}/${date.year} • ${kFruits[e['level'] as int].name}'));
      }));
  }
}
