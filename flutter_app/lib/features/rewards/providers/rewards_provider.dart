import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/models/reward.dart';

/// Household reward totals per member.
final rewardsProvider = FutureProvider<List<MemberRewardTotals>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/rewards');
  final data = resp.data as Map<String, dynamic>;
  return (data['members'] as List<dynamic>)
      .map((e) => MemberRewardTotals.fromJson(e as Map<String, dynamic>))
      .toList();
});
