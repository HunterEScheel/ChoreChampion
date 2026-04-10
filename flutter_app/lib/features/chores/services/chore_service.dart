import 'package:dio/dio.dart';

import '../../../core/models/chore.dart';
import '../../../core/models/submission.dart';

class ChoreService {
  ChoreService(this._dio);
  final Dio _dio;

  /// Fetch available chores for the active member.
  Future<List<Chore>> getAvailableChores() async {
    final resp = await _dio.get('/chores');
    return (resp.data as List<dynamic>)
        .map((e) => Chore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Submit a chore completion.
  Future<Submission> submitChore({
    required String choreId,
    String? notes,
  }) async {
    final resp = await _dio.post('/submissions', data: {
      'chore_id': choreId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Submission.fromJson(resp.data as Map<String, dynamic>);
  }
}
