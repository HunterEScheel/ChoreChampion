import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../providers/admin_providers.dart';

/// Devices tab: generate QR code for joining, list connected devices (future).
class DevicesTab extends ConsumerStatefulWidget {
  const DevicesTab({super.key});

  @override
  ConsumerState<DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends ConsumerState<DevicesTab> {
  String? _qrData;
  DateTime? _expiresAt;
  bool _generating = false;

  Future<void> _generateQr() async {
    setState(() {
      _generating = true;
      _qrData = null;
    });

    try {
      final service = ref.read(adminServiceProvider);
      final result = await service.createJoinToken();
      final token = result['token'] as String;
      final expiresAt = DateTime.parse(result['expires_at'] as String);

      // Get household ID from storage
      final storage = ref.read(secureStorageProvider);
      final householdId = await storage.getHouseholdId();

      setState(() {
        // QR data format: "householdId|joinToken"
        _qrData = '$householdId|$token';
        _expiresAt = expiresAt;
        _generating = false;
      });
    } on DioException catch (e) {
      setState(() => _generating = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Join Code', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Generate a QR code for a new device to join your household. '
            'The code expires after 10 minutes.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _generating ? null : _generateQr,
            icon: const Icon(Icons.qr_code),
            label: Text(_generating ? 'Generating...' : 'Generate Join Code'),
          ),
          if (_qrData != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Display the join data as text (QR rendering requires
                    // a QR generation package — for MVP show the raw data)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _qrData!,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_expiresAt != null)
                      Text(
                        'Expires: ${_expiresAt!.toLocal().toString().substring(0, 19)}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Show this code to the new device, or have them scan it as a QR code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
