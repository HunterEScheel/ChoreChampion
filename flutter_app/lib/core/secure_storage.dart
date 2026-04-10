import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

/// Thin wrapper around [FlutterSecureStorage] for typed reads/writes.
class SecureStorage {
  SecureStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // ── JWT ───────────────────────────────────────────────────────────

  Future<String?> getJwt() => _storage.read(key: kStorageKeyJwt);
  Future<void> setJwt(String jwt) => _storage.write(key: kStorageKeyJwt, value: jwt);

  // ── Household ─────────────────────────────────────────────────────

  Future<String?> getHouseholdId() => _storage.read(key: kStorageKeyHouseholdId);
  Future<void> setHouseholdId(String id) =>
      _storage.write(key: kStorageKeyHouseholdId, value: id);

  // ── Admin flag ────────────────────────────────────────────────────

  Future<bool> getIsAdmin() async {
    final val = await _storage.read(key: kStorageKeyIsAdmin);
    return val == 'true';
  }

  Future<void> setIsAdmin(bool isAdmin) =>
      _storage.write(key: kStorageKeyIsAdmin, value: isAdmin.toString());

  // ── Active member ─────────────────────────────────────────────────

  Future<String?> getActiveMemberId() =>
      _storage.read(key: kStorageKeyActiveMemberId);

  Future<void> setActiveMember(String id, String name) async {
    await _storage.write(key: kStorageKeyActiveMemberId, value: id);
    await _storage.write(key: kStorageKeyActiveMemberName, value: name);
  }

  Future<String?> getActiveMemberName() =>
      _storage.read(key: kStorageKeyActiveMemberName);

  // ── Clear all ─────────────────────────────────────────────────────

  Future<void> clearAll() => _storage.deleteAll();
}
