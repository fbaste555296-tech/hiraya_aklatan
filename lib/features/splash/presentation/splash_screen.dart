import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_providers.dart';

/// Splash screen shown while the initial auth state is resolved.
///
/// Waits for the first emission of the Firebase auth stream, then redirects
/// signed-in users to the library and signed-out users to login.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Defer navigation until after the first frame so the context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveStartRoute());
  }

  void _resolveStartRoute() {
    if (!mounted) return;

    final firebaseUser = ref.read(firebaseUserProvider);
    final destination = firebaseUser.maybeWhen(
      data: (user) => user != null ? RouteNames.library : RouteNames.login,
      orElse: () => RouteNames.login,
    );

    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories,
              size: 88,
              color: AppColors.accent,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Hiraya Aklatan',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Digital Library',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
