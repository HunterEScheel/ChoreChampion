import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../shared/widgets/difficulty_badge.dart';
import '../providers/admin_providers.dart';

class ChoresTab extends ConsumerWidget {
  const ChoresTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choresAsync = ref.watch(adminChoresProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Chore'),
            ),
          ),
        ),
        Expanded(
          child: choresAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (chores) => ListView.builder(
              itemCount: chores.length,
              itemBuilder: (_, i) {
                final chore = chores[i];
                return ListTile(
                  title: Text(chore.name),
                  subtitle: Row(
                    children: [
                      DifficultyBadge(difficulty: chore.difficulty),
                      const SizedBox(width: 8),
                      Text(chore.cadence),
                    ],
                  ),
                  trailing: Switch(
                    value: chore.active,
                    onChanged: (val) => _toggleActive(ref, chore.choreId, val),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleActive(WidgetRef ref, String choreId, bool active) async {
    try {
      final service = ref.read(adminServiceProvider);
      await service.patchChore(choreId, {'active': active});
      ref.invalidate(adminChoresProvider);
    } catch (_) {}
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    String difficulty = 'easy';
    String cadence = 'daily';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Chore'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: difficulty,
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: ['easy', 'medium', 'hard', 'flexible']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => difficulty = v ?? difficulty),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: cadence,
                decoration: const InputDecoration(labelText: 'Cadence'),
                items: ['daily', 'weekly', 'monthly', 'on_request']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => cadence = v ?? cadence),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (result != true || nameCtrl.text.trim().isEmpty) {
      nameCtrl.dispose();
      return;
    }

    try {
      final service = ref.read(adminServiceProvider);
      await service.createChore(
        name: nameCtrl.text.trim(),
        difficulty: difficulty,
        cadence: cadence,
      );
      ref.invalidate(adminChoresProvider);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(e))));
      }
    }
    nameCtrl.dispose();
  }
}
