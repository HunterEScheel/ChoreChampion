import 'package:dio/dio.dart';

import '../../../core/models/chore.dart';
import '../../../core/models/household.dart';
import '../../../core/models/reward.dart';
import '../../../core/models/submission.dart';

/// API calls for admin-only operations.
class AdminService {
  AdminService(this._dio);
  final Dio _dio;

  // ── Members ─────────────────────────────────────────────────────

  Future<Member> createMember(String name) async {
    final resp = await _dio.post('/members', data: {'name': name});
    return Member.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Member> renameMember(String memberId, String name) async {
    final resp =
        await _dio.patch('/members/$memberId', data: {'name': name});
    return Member.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteMember(String memberId) async {
    await _dio.delete('/members/$memberId');
  }

  // ── Chores ──────────────────────────────────────────────────────

  Future<Chore> createChore({
    required String name,
    required String difficulty,
    required String cadence,
    bool active = true,
  }) async {
    final resp = await _dio.post('/chores', data: {
      'name': name,
      'difficulty': difficulty,
      'cadence': cadence,
      'active': active,
    });
    return Chore.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Chore> patchChore(String choreId, Map<String, dynamic> fields) async {
    final resp = await _dio.patch('/chores/$choreId', data: fields);
    return Chore.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Submissions ─────────────────────────────────────────────────

  Future<List<Submission>> getSubmissions({int days = 7, String? memberId}) async {
    final params = <String, dynamic>{'days': days};
    if (memberId != null) params['member_id'] = memberId;
    final resp = await _dio.get('/submissions', queryParameters: params);
    return (resp.data as List<dynamic>)
        .map((e) => Submission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Submission> rejectSubmission(String id, String reason) async {
    final resp =
        await _dio.patch('/submissions/$id/reject', data: {'reason': reason});
    return Submission.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Submission> unrejectSubmission(String id) async {
    final resp = await _dio.patch('/submissions/$id/unreject');
    return Submission.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Reward categories ───────────────────────────────────────────

  Future<List<RewardCategory>> getCategories() async {
    final resp = await _dio.get('/rewards/categories');
    return (resp.data as List<dynamic>)
        .map((e) => RewardCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RewardCategory> createCategory(String name, String type) async {
    final resp = await _dio
        .post('/rewards/categories', data: {'name': name, 'type': type});
    return RewardCategory.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/rewards/categories/$id');
  }

  // ── Difficulty mappings ─────────────────────────────────────────

  Future<List<DifficultyMapping>> getMappings() async {
    final resp = await _dio.get('/rewards/mappings');
    return (resp.data as List<dynamic>)
        .map((e) => DifficultyMapping.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DifficultyMapping>> saveMappings(
      List<Map<String, dynamic>> mappings) async {
    final resp = await _dio.put('/rewards/mappings', data: mappings);
    return (resp.data as List<dynamic>)
        .map((e) => DifficultyMapping.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Join tokens ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> createJoinToken() async {
    final resp = await _dio.post('/devices/join-tokens');
    return resp.data as Map<String, dynamic>;
  }
}
