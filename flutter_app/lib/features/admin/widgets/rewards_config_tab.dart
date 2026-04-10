import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/models/reward.dart';
import '../providers/admin_providers.dart';

class RewardsConfigTab extends ConsumerWidget {
  const RewardsConfigTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(rewardCategoriesProvider);
    final mappingsAsync = ref.watch(difficultyMappingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Categories section ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reward Categories',
                  style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => _showAddCategoryDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          catsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (cats) => cats.isEmpty
                ? const Text('No categories yet.')
                : Column(
                    children: cats
                        .map((c) => ListTile(
                              title: Text(c.name),
                              subtitle: Text('Type: ${c.type}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    _deleteCategory(context, ref, c),
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const Divider(height: 32),

          // ── Mappings section ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Difficulty Rewards',
                  style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => _showMappingsEditor(context, ref),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          mappingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (mappings) {
              if (mappings.isEmpty) {
                return const Text('No mappings configured yet.');
              }
              return _MappingsTable(mappings: mappings, ref: ref);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    String type = 'integer';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Reward Category'),
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
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['integer', 'float', 'boolean']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setDialogState(() => type = v ?? type),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
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
      await service.createCategory(nameCtrl.text.trim(), type);
      ref.invalidate(rewardCategoriesProvider);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(e))));
      }
    }
    nameCtrl.dispose();
  }

  Future<void> _deleteCategory(
      BuildContext context, WidgetRef ref, RewardCategory cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"? This also removes its mappings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(adminServiceProvider);
      await service.deleteCategory(cat.rewardCategoryId);
      ref.invalidate(rewardCategoriesProvider);
      ref.invalidate(difficultyMappingsProvider);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(e))));
      }
    }
  }

  Future<void> _showMappingsEditor(BuildContext context, WidgetRef ref) async {
    final cats = ref.read(rewardCategoriesProvider).value ?? [];
    final existing = ref.read(difficultyMappingsProvider).value ?? [];
    if (cats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create reward categories first.')));
      return;
    }

    // Build editable grid: difficulty x category → value
    final difficulties = ['easy', 'medium', 'hard', 'flexible'];
    final controllers = <String, Map<String, TextEditingController>>{};

    for (final d in difficulties) {
      controllers[d] = {};
      for (final c in cats) {
        final match = existing
            .where(
                (m) => m.difficulty == d && m.rewardCategoryId == c.rewardCategoryId)
            .toList();
        final val = match.isNotEmpty ? match.first.value.toString() : '';
        controllers[d]![c.rewardCategoryId] = TextEditingController(text: val);
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Reward Mappings'),
        content: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Difficulty')),
              ...cats.map((c) => DataColumn(label: Text(c.name))),
            ],
            rows: difficulties
                .map((d) => DataRow(cells: [
                      DataCell(Text(d)),
                      ...cats.map((c) => DataCell(SizedBox(
                            width: 60,
                            child: TextField(
                              controller: controllers[d]![c.rewardCategoryId],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  border: InputBorder.none, isDense: true),
                            ),
                          ))),
                    ]))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) {
      for (final row in controllers.values) {
        for (final ctrl in row.values) {
          ctrl.dispose();
        }
      }
      return;
    }

    // Build mappings list from controllers
    final mappings = <Map<String, dynamic>>[];
    for (final d in difficulties) {
      for (final c in cats) {
        final text = controllers[d]![c.rewardCategoryId]!.text.trim();
        final val = double.tryParse(text);
        if (val != null && val > 0) {
          mappings.add({
            'difficulty': d,
            'reward_category_id': c.rewardCategoryId,
            'value': val,
          });
        }
      }
    }

    for (final row in controllers.values) {
      for (final ctrl in row.values) {
        ctrl.dispose();
      }
    }

    try {
      final service = ref.read(adminServiceProvider);
      await service.saveMappings(mappings);
      ref.invalidate(difficultyMappingsProvider);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(e))));
      }
    }
  }
}

class _MappingsTable extends StatelessWidget {
  const _MappingsTable({required this.mappings, required this.ref});
  final List<DifficultyMapping> mappings;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(rewardCategoriesProvider).value ?? [];
    final catNames = {for (final c in cats) c.rewardCategoryId: c.name};

    // Group by difficulty
    final grouped = <String, Map<String, double>>{};
    for (final m in mappings) {
      grouped.putIfAbsent(m.difficulty, () => {});
      final name = catNames[m.rewardCategoryId] ?? m.rewardCategoryId;
      grouped[m.difficulty]![name] = m.value;
    }

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          children: [
            const Padding(
                padding: EdgeInsets.all(8),
                child:
                    Text('Difficulty', style: TextStyle(fontWeight: FontWeight.w600))),
            ...catNames.values.map((n) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text(n, style: const TextStyle(fontWeight: FontWeight.w600)))),
          ],
        ),
        for (final entry in grouped.entries)
          TableRow(children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(entry.key)),
            ...catNames.values.map((n) {
              final val = entry.value[n];
              final display = val == null
                  ? '-'
                  : (val == val.truncateToDouble()
                      ? val.toInt().toString()
                      : val.toStringAsFixed(2));
              return Padding(
                  padding: const EdgeInsets.all(8), child: Text(display));
            }),
          ]),
      ],
    );
  }
}
