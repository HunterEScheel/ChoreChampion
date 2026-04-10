import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Detects the current Wi-Fi SSID and hashes it for the backend.
class WifiService {
  final _info = NetworkInfo();

  /// Returns the SHA-256 hash of the current Wi-Fi SSID, or null if unavailable.
  Future<String?> getSsidHash() async {
    try {
      final ssid = await _info.getWifiName();
      if (ssid == null || ssid.isEmpty) return null;
      // NetworkInfo wraps SSID in quotes on some platforms
      final cleaned = ssid.replaceAll('"', '');
      if (cleaned.isEmpty || cleaned == '<unknown ssid>') return null;
      final bytes = utf8.encode(cleaned);
      return sha256.convert(bytes).toString();
    } catch (_) {
      return null;
    }
  }
}
