import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chore.dart';
import '../providers/chores_provider.dart';
import '../widgets/chore_card.dart';
import '../widgets/submit_chore_sheet.dart';

class ChoreListScreen extends ConsumerWidget {
  const ChoreListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choresAsync = ref.watch(availableChoresProvider);

    return choresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $e'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(availableChoresProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (chores) {
        if (chores.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('All caught up!',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('No chores available right now.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Group by difficulty
        final grouped = _groupByDifficulty(chores);
        final order = ['easy', 'medium', 'hard', 'flexible'];

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(availableChoresProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final difficulty in order)
                if (grouped.containsKey(difficulty)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      '${difficulty[0].toUpperCase()}${difficulty.substring(1)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey),
                    ),
                  ),
                  ...grouped[difficulty]!.map((chore) => ChoreCard(
                        chore: chore,
                        onTap: () => _showSubmitSheet(context, chore),
                      )),
                ],
            ],
          ),
        );
      },
    );
  }

  Map<String, List<Chore>> _groupByDifficulty(List<Chore> chores) {
    final map = <String, List<Chore>>{};
    for (final chore in chores) {
      map.putIfAbsent(chore.difficulty, () => []).add(chore);
    }
    return map;
  }

  void _showSubmitSheet(BuildContext context, Chore chore) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SubmitChoreSheet(chore: chore),
    );
  }
}
