import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Startup screen: checks stored JWT and routes accordingly.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (prev, next) {
      next.whenData((auth) {
        if (!context.mounted) return;
        if (!auth.isAuthenticated) {
          context.go('/join');
        } else if (!auth.hasActiveMember) {
          context.go('/select-member');
        } else {
          context.go('/chores');
        }
      });
    });

    return Scaffold(
      body: Center(
        child: authAsync.when(
          loading: () => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
          error: (e, _) => Text('Error: $e'),
          data: (_) => const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
