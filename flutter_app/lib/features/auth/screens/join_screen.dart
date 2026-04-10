import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api_client.dart';
import '../../../core/wifi_service.dart';
import '../providers/auth_provider.dart';

/// Join flow: auto-detect Wi-Fi SSID first, fall back to QR scan.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryAutoJoin();
  }

  Future<void> _tryAutoJoin() async {
    try {
      final ssidHash = await WifiService().getSsidHash();
      if (ssidHash == null) {
        setState(() => _checking = false);
        return;
      }

      // Try joining with SSID — this will fail if no household matches
      final dio = ref.read(dioProvider);
      final resp = await dio.post('/devices/join', data: {
        'household_id': '00000000-0000-0000-0000-000000000000', // placeholder
        'ssid_hash': ssidHash,
        'join_token': null,
        'device_name': 'Mobile Device',
      });
      final jwt = (resp.data as Map<String, dynamic>)['jwt'] as String;
      await ref.read(authStateProvider.notifier).onJoin(jwt, false);
      if (mounted) context.go('/select-member');
    } on DioException {
      // SSID not recognized — show manual join options
      setState(() => _checking = false);
    } catch (_) {
      setState(() => _checking = false);
    }
  }

  Future<void> _onQrScanned(String data) async {
    // QR data format: "householdId|joinToken"
    final parts = data.split('|');
    if (parts.length != 2) {
      setState(() => _error = 'Invalid QR code');
      return;
    }
    final householdId = parts[0];
    final joinToken = parts[1];

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final jwt = await authService.joinHousehold(
        householdId: householdId,
        deviceName: 'Mobile Device',
        joinToken: joinToken,
      );
      await ref.read(authStateProvider.notifier).onJoin(jwt, false);
      if (mounted) context.go('/select-member');
    } on DioException catch (e) {
      setState(() {
        _checking = false;
        _error = parseApiError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking your network...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Join Household')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How would you like to join?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
              const SizedBox(height: 16),
            ],
            // QR Scanner
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Scan QR Code',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: MobileScanner(
                        onDetect: (capture) {
                          final barcode = capture.barcodes.firstOrNull;
                          if (barcode?.rawValue != null) {
                            _onQrScanned(barcode!.rawValue!);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('OR', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/create-household'),
              icon: const Icon(Icons.add_home),
              label: const Text('Create New Household'),
            ),
          ],
        ),
      ),
    );
  }
}
