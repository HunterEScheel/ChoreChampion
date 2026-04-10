import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/secure_storage.dart';
import '../../../core/models/household.dart';
import '../services/auth_service.dart';

/// Immutable snapshot of auth state.
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isAdmin = false,
    this.hasActiveMember = false,
    this.household,
    this.members,
  });

  final bool isAuthenticated;
  final bool isAdmin;
  final bool hasActiveMember;
  final Household? household;
  final List<Member>? members;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isAdmin,
    bool? hasActiveMember,
    Household? household,
    List<Member>? members,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isAdmin: isAdmin ?? this.isAdmin,
        hasActiveMember: hasActiveMember ?? this.hasActiveMember,
        household: household ?? this.household,
        members: members ?? this.members,
      );
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});

/// Main auth state — async because it reads from secure storage on init.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  SecureStorage get _storage => ref.read(secureStorageProvider);
  AuthService get _authService => ref.read(authServiceProvider);

  @override
  Future<AuthState> build() async {
    // Check for stored JWT on startup
    final jwt = await _storage.getJwt();
    if (jwt == null) return const AuthState();

    try {
      final meResp = await _authService.getMe();
      final isAdmin = await _storage.getIsAdmin();
      final activeMemberId = await _storage.getActiveMemberId();

      return AuthState(
        isAuthenticated: true,
        isAdmin: isAdmin,
        hasActiveMember: activeMemberId != null,
        household: meResp.household,
        members: meResp.members,
      );
    } catch (_) {
      // Token invalid/expired — clear and start fresh
      await _storage.clearAll();
      return const AuthState();
    }
  }

  /// After bootstrap: persist JWT + device info, update state.
  Future<void> onBootstrap(BootstrapResponse resp) async {
    await _storage.setJwt(resp.jwt);
    await _storage.setHouseholdId(resp.household.householdId);
    await _storage.setIsAdmin(resp.device.isAdmin);

    final meResp = await _authService.getMe();
    state = AsyncData(AuthState(
      isAuthenticated: true,
      isAdmin: resp.device.isAdmin,
      hasActiveMember: false,
      household: meResp.household,
      members: meResp.members,
    ));
  }

  /// After join: persist JWT, fetch household.
  Future<void> onJoin(String jwt, bool isAdmin) async {
    await _storage.setJwt(jwt);
    await _storage.setIsAdmin(isAdmin);

    final meResp = await _authService.getMe();
    await _storage.setHouseholdId(meResp.household.householdId);

    state = AsyncData(AuthState(
      isAuthenticated: true,
      isAdmin: isAdmin,
      hasActiveMember: false,
      household: meResp.household,
      members: meResp.members,
    ));
  }

  /// Mark that the user has selected an active member.
  void setActiveMember(Member member) {
    final current = state.value ?? const AuthState();
    state = AsyncData(current.copyWith(hasActiveMember: true));
  }

  /// Refresh member list (after admin adds/removes a member).
  Future<void> refreshMembers() async {
    final meResp = await _authService.getMe();
    final current = state.value ?? const AuthState();
    state = AsyncData(current.copyWith(members: meResp.members));
  }

  /// Log out: clear storage and reset state.
  Future<void> logout() async {
    await _storage.clearAll();
    state = const AsyncData(AuthState());
  }
}
