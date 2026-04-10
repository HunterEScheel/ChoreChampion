import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants.dart';
import 'secure_storage.dart';

/// Provides a configured [Dio] instance with JWT and active-member interceptors.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_AuthInterceptor(ref));
  return dio;
});

final secureStorageProvider = Provider<SecureStorage>((_) => SecureStorage());

/// Attaches `Authorization: Bearer <jwt>` and `X-Active-Member` headers.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._ref);
  final Ref _ref;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = _ref.read(secureStorageProvider);

    final jwt = await storage.getJwt();
    if (jwt != null) {
      options.headers['Authorization'] = 'Bearer $jwt';
    }

    final memberId = await storage.getActiveMemberId();
    if (memberId != null) {
      options.headers[kHeaderActiveMember] = memberId;
    }

    handler.next(options);
  }
}

/// Parse the standard error envelope `{code, detail}` from the API.
String parseApiError(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    return data['detail']?.toString() ?? e.message ?? 'Unknown error';
  }
  return e.message ?? 'Network error';
}
