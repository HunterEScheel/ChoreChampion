import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../providers/rewards_provider.dart';
import '../widgets/member_reward_card.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);
    final activeMemberId = ref.watch(
      FutureProvider<String?>((ref) async {
        final storage = ref.watch(secureStorageProvider);
        return storage.getActiveMemberId();
      }),
    );

    return rewardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $e'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(rewardsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (members) {
        if (members.isEmpty) {
          return const Center(
            child: Text('No reward data yet.', style: TextStyle(color: Colors.grey)),
          );
        }

        final currentId = activeMemberId.value;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(rewardsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (_, i) => MemberRewardCard(
              member: members[i],
              isActive: members[i].memberId == currentId,
            ),
          ),
        );
      },
    );
  }
}
