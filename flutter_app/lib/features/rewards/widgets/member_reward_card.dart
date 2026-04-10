import 'package:flutter/material.dart';

import '../../../core/models/reward.dart';

class MemberRewardCard extends StatelessWidget {
  const MemberRewardCard({
    required this.member,
    this.isActive = false,
    super.key,
  });
  final MemberRewardTotals member;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: isActive ? colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isActive
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  child: Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  member.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (member.totals.isEmpty)
              Text('No rewards earned yet.',
                  style: TextStyle(color: Colors.grey.shade500))
            else
              ...member.totals.entries.map((e) {
                final display = e.value == e.value.truncateToDouble()
                    ? e.value.toInt().toString()
                    : e.value.toStringAsFixed(2);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key),
                      Text(
                        display,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
