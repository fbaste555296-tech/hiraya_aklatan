// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../data/models/user_model.dart';
import '../../../auth/providers/auth_providers.dart';

/// Profile screen showing the current user's info, VIP status, and logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User info card - uses AsyncValueWidget for proper loading/error states
              Consumer(
                builder: (context, ref, _) {
                  final userAsync = ref.watch(currentUserViewModelProvider);

                  return AsyncValueWidget<UserModel?>(
                    value: userAsync,
                    loading: () => const _ProfileSkeleton(),
                    error: (error, _) => ErrorBanner(
                      message: 'Failed to load profile: $error',
                      onRetry: () => ref.read(currentUserViewModelProvider.notifier).refresh(),
                    ),
                    data: (user) {
                      if (user == null) {
                        return const _NotSignedInBanner();
                      }
                      return _UserInfoCard(user: user);
                    },
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Quick links
              Text(
                'Quick Links',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Consumer(
                builder: (context, ref, _) {
                  final userAsync = ref.watch(currentUserViewModelProvider);

                  return userAsync.when(
                    data: (user) {
                      if (user == null) return const SizedBox.shrink();
                      return _QuickLinksCard(user: user);
                    },
                    loading: () => const _QuickLinksSkeleton(),
                    error: (_, _) => const SizedBox.shrink(),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Logout button
              AppButton(
                onPressed: authState.isLoading
                    ? null
                    : () => authNotifier.signOut(),
                text: 'Sign Out',
                icon: Icons.logout,
                isLoading: authState.isLoading,
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader for profile card.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for quick links.
class _QuickLinksSkeleton extends StatelessWidget {
  const _QuickLinksSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner shown when user is not signed in.
class _NotSignedInBanner extends StatelessWidget {
  const _NotSignedInBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.person_off,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Not signed in',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Please sign in to view your profile.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// User info card displaying profile details.
class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              user.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: user.isVipActive
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                user.isVipActive ? 'VIP Active' : 'Reader',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: user.isVipActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (user.isVipActive && user.vipExpiry != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Expires: ${Formatters.date(user.vipExpiry!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quick links card with navigation options.
class _QuickLinksCard extends StatelessWidget {
  const _QuickLinksCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.star, color: AppColors.accent),
            title: const Text('VIP Subscription'),
            subtitle: Text(
              user.isVipActive
                  ? 'Manage your subscription'
                  : 'Unlock all early-access chapters',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.vip),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Payment History'),
            subtitle: const Text('View your payment status'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.paymentHistory),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('My Library'),
            subtitle: const Text('Continue reading'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.myLibrary),
          ),
        ],
      ),
    );
  }
}