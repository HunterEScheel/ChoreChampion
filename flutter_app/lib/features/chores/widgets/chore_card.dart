import 'package:flutter/material.dart';

import '../../../core/models/chore.dart';
import '../../../shared/widgets/difficulty_badge.dart';

class ChoreCard extends StatelessWidget {
  const ChoreCard({required this.chore, required this.onTap, super.key});
  final Chore chore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chore.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        DifficultyBadge(difficulty: chore.difficulty),
                        const SizedBox(width: 8),
                        Text(
                          _formatCadence(chore.cadence),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    if (chore.rewards.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: chore.rewards.entries
                            .map((e) => _RewardChip(
                                  name: e.key,
                                  value: e.value,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCadence(String cadence) {
    return switch (cadence) {
      'daily' => 'Daily',
      'weekly' => 'Weekly',
      'monthly' => 'Monthly',
      'on_request' => 'On Request',
      _ => cadence,
    };
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.name, required this.value});
  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    final display = value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    return Chip(
      label: Text('$name: $display', style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
