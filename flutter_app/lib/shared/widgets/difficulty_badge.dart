import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Small colored chip showing chore difficulty.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({required this.difficulty, super.key});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        difficulty[0].toUpperCase() + difficulty.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
