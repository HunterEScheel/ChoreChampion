import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/secure_storage.dart';

/// Exposes the currently active member's display name (read from storage).
final activeMemberNameProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.getActiveMemberName();
});
