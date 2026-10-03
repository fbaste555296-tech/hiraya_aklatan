import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../providers/admin_providers.dart';

/// Admin dashboard with statistics and quick navigation.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: statsAsync.when(
        loading: () => const LoadingView(message: 'Loading stats...'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(adminStatsProvider),
        ),
        data: (stats) => _buildContent(context, stats),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdminStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                icon: Icons.library_books,
                label: 'Total Books',
                value: '${stats.totalBooks}',
                color: AppColors.primary,
              ),
              _StatCard(
                icon: Icons.people,
                label: 'Total Users',
                value: '${stats.totalUsers}',
                color: AppColors.accent,
              ),
              _StatCard(
                icon: Icons.pending_actions,
                label: 'Pending Payments',
                value: '${stats.pendingPayments}',
                color: AppColors.statusPending,
              ),
              _StatCard(
                icon: Icons.star,
                label: 'VIP Users',
                value: '${stats.vipUsers}',
                color: AppColors.statusApproved,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Quick actions
          Text(
            'Manage',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          _AdminMenuItem(
            icon: Icons.library_books,
            title: 'Books',
            subtitle: 'Add, edit, or remove books',
            onTap: () => context.push(RouteNames.adminBooks),
          ),
          _AdminMenuItem(
            icon: Icons.list_alt,
            title: 'Chapters',
            subtitle: 'Manage chapter content and pricing',
            onTap: () => context.push(RouteNames.adminBooks),
          ),
          _AdminMenuItem(
            icon: Icons.payment,
            title: 'Payment Review',
            subtitle: 'Approve or reject payments',
            onTap: () => context.push(RouteNames.adminPayments),
          ),
          _AdminMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Payment methods and VIP prices',
            onTap: () => context.push(RouteNames.adminSettings),
          ),
          _AdminMenuItem(
            icon: Icons.people,
            title: 'Users',
            subtitle: 'View all registered users',
            onTap: () => context.push(RouteNames.adminUsers),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Exception:')) {
      return message.substring(message.indexOf('Exception:') + 11).trim();
    }
    return AppConstants.errorGeneric;
  }
}

/// Statistics card for the dashboard.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Menu item for admin navigation.
class _AdminMenuItem extends StatelessWidget {
  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
