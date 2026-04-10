import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/models/chore.dart';
import '../../../core/models/reward.dart';
import '../../../core/models/submission.dart';
import '../services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(dioProvider));
});

final adminSubmissionsProvider =
    FutureProvider.family<List<Submission>, int>((ref, days) async {
  final service = ref.watch(adminServiceProvider);
  return service.getSubmissions(days: days);
});

final adminChoresProvider = FutureProvider<List<Chore>>((ref) async {
  final dio = ref.watch(dioProvider);
  // Use a direct call since the regular /chores requires X-Active-Member.
  // For admin listing we can fetch all chores (active + inactive).
  // For now we reuse the same endpoint — admin has the member header set.
  final resp = await dio.get('/chores');
  return (resp.data as List<dynamic>)
      .map((e) => Chore.fromJson(e as Map<String, dynamic>))
      .toList();
});

final rewardCategoriesProvider =
    FutureProvider<List<RewardCategory>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.getCategories();
});

final difficultyMappingsProvider =
    FutureProvider<List<DifficultyMapping>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.getMappings();
});
