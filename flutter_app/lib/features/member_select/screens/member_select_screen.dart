import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
import '../../../core/models/household.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/active_member_provider.dart';

/// "Who's doing chores today?" grid.
class MemberSelectScreen extends ConsumerWidget {
  const MemberSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final members = authAsync.value?.members ?? [];
    final householdName = authAsync.value?.household?.name ?? 'Household';

    return Scaffold(
      appBar: AppBar(title: Text(householdName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Who's doing chores today?",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            if (members.isEmpty)
              const _EmptyState()
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) => _MemberCard(
                    member: members[index],
                    onTap: () => _selectMember(context, ref, members[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMember(
      BuildContext context, WidgetRef ref, Member member) async {
    final storage = ref.read(secureStorageProvider);
    await storage.setActiveMember(member.memberId, member.name);
    ref.read(authStateProvider.notifier).setActiveMember(member);
    ref.invalidate(activeMemberNameProvider);
    if (context.mounted) context.go('/chores');
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});
  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 24,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                member.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No family members yet.'),
          const SizedBox(height: 8),
          const Text(
            'An admin needs to add members\nfrom the Admin panel.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
