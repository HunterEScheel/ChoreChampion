import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
import '../../../core/wifi_service.dart';
import '../providers/auth_provider.dart';

class CreateHouseholdScreen extends ConsumerStatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  ConsumerState<CreateHouseholdScreen> createState() =>
      _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends ConsumerState<CreateHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _deviceNameCtrl = TextEditingController(text: 'My Device');
  String _timezone = 'America/Chicago';
  bool _loading = false;
  String? _error;

  static const _timezones = [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Phoenix',
    'UTC',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deviceNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ssidHash = await WifiService().getSsidHash();
      final authService = ref.read(authServiceProvider);
      final resp = await authService.createHousehold(
        householdName: _nameCtrl.text.trim(),
        timezone: _timezone,
        deviceName: _deviceNameCtrl.text.trim(),
        ssidHash: ssidHash,
      );
      await ref.read(authStateProvider.notifier).onBootstrap(resp);
      if (mounted) context.go('/select-member');
    } on DioException catch (e) {
      setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Household')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onErrorContainer)),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Household Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _timezone,
                decoration: const InputDecoration(labelText: 'Timezone'),
                items: _timezones
                    .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                    .toList(),
                onChanged: (v) => setState(() => _timezone = v ?? _timezone),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deviceNameCtrl,
                decoration: const InputDecoration(labelText: 'Device Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create Household'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
