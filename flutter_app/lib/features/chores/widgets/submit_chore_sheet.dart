import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/models/chore.dart';
import '../../../shared/widgets/difficulty_badge.dart';
import '../providers/chores_provider.dart';

/// Bottom sheet for confirming chore submission with optional notes.
class SubmitChoreSheet extends ConsumerStatefulWidget {
  const SubmitChoreSheet({required this.chore, super.key});
  final Chore chore;

  @override
  ConsumerState<SubmitChoreSheet> createState() => _SubmitChoreSheetState();
}

class _SubmitChoreSheetState extends ConsumerState<SubmitChoreSheet> {
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(choreServiceProvider);
      await service.submitChore(
        choreId: widget.chore.choreId,
        notes: _notesCtrl.text.trim(),
      );
      // Refresh the chore list
      ref.invalidate(availableChoresProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chore = widget.chore;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            chore.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              DifficultyBadge(difficulty: chore.difficulty),
              const SizedBox(width: 12),
              if (chore.rewards.isNotEmpty)
                Text(
                  chore.rewards.entries
                      .map((e) => '${e.key}: ${e.value == e.value.truncateToDouble() ? e.value.toInt() : e.value}')
                      .join(', '),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Any details about the chore...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit Chore'),
          ),
        ],
      ),
    );
  }
}
