import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/models/chore.dart';
import '../services/chore_service.dart';

final choreServiceProvider = Provider<ChoreService>((ref) {
  return ChoreService(ref.watch(dioProvider));
});

/// Available chores for the active member. Invalidate after submission.
final availableChoresProvider = FutureProvider<List<Chore>>((ref) async {
  final service = ref.watch(choreServiceProvider);
  return service.getAvailableChores();
});
