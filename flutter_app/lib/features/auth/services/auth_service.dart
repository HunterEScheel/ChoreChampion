import 'package:dio/dio.dart';

import '../../../core/models/household.dart';

/// API calls for authentication and household management.
class AuthService {
  AuthService(this._dio);
  final Dio _dio;

  /// Bootstrap: create household + first admin device.
  Future<BootstrapResponse> createHousehold({
    required String householdName,
    required String timezone,
    required String deviceName,
    String? ssidHash,
  }) async {
    final resp = await _dio.post('/households', data: {
      'household_name': householdName,
      'timezone': timezone,
      'device_name': deviceName,
      'ssid_hash': ssidHash,
    });
    return BootstrapResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  /// Join a household via SSID hash or join token.
  Future<String> joinHousehold({
    required String householdId,
    required String deviceName,
    String? ssidHash,
    String? joinToken,
  }) async {
    final resp = await _dio.post('/devices/join', data: {
      'household_id': householdId,
      'ssid_hash': ssidHash,
      'join_token': joinToken,
      'device_name': deviceName,
    });
    return (resp.data as Map<String, dynamic>)['jwt'] as String;
  }

  /// Validate current JWT by fetching household info.
  Future<HouseholdMeResponse> getMe() async {
    final resp = await _dio.get('/households/me');
    return HouseholdMeResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  /// Generate a join token (admin only).
  Future<Map<String, dynamic>> createJoinToken() async {
    final resp = await _dio.post('/devices/join-tokens');
    return resp.data as Map<String, dynamic>;
  }
}
