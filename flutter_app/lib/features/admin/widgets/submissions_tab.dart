import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/models/submission.dart';
import '../providers/admin_providers.dart';

class SubmissionsTab extends ConsumerStatefulWidget {
  const SubmissionsTab({super.key});

  @override
  ConsumerState<SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends ConsumerState<SubmissionsTab> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(adminSubmissionsProvider(_days));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Last '),
              DropdownButton<int>(
                value: _days,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 day')),
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                ],
                onChanged: (v) => setState(() => _days = v ?? 7),
              ),
            ],
          ),
        ),
        Expanded(
          child: submissionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (subs) {
              if (subs.isEmpty) {
                return const Center(child: Text('No submissions in this period.'));
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(adminSubmissionsProvider(_days)),
                child: ListView.builder(
                  itemCount: subs.length,
                  itemBuilder: (_, i) => _SubmissionTile(
                    submission: subs[i],
                    onReject: () => _showRejectDialog(subs[i]),
                    onUnreject: () => _unreject(subs[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showRejectDialog(Submission sub) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Submission'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;

    try {
      final service = ref.read(adminServiceProvider);
      await service.rejectSubmission(sub.submissionId, reason);
      ref.invalidate(adminSubmissionsProvider(_days));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(e))));
      }
    }
  }

  Future<void> _unreject(Submission sub) async {
    try {
      final service = ref.read(adminServiceProvider);
      await service.unrejectSubmission(sub.submissionId);
      ref.invalidate(adminSubmissionsProvider(_days));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(e))));
      }
    }
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({
    required this.submission,
    required this.onReject,
    required this.onUnreject,
  });
  final Submission submission;
  final VoidCallback onReject;
  final VoidCallback onUnreject;

  @override
  Widget build(BuildContext context) {
    final approved = submission.approved;
    return ListTile(
      leading: Icon(
        approved ? Icons.check_circle : Icons.cancel,
        color: approved ? Colors.green : Colors.red,
      ),
      title: Text('Chore: ${submission.choreId.substring(0, 8)}...'),
      subtitle: Text(
        approved
            ? 'Approved${submission.notes != null ? " - ${submission.notes}" : ""}'
            : 'Rejected: ${submission.rejectionReason ?? ""}',
      ),
      trailing: approved
          ? TextButton(onPressed: onReject, child: const Text('Reject'))
          : TextButton(onPressed: onUnreject, child: const Text('Unreject')),
    );
  }
}
