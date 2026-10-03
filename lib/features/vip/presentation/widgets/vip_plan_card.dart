import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/providers/auth_providers.dart';

/// VIP subscription plan card.
class VipPlanCard extends ConsumerWidget {
  const VipPlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.duration,
    required this.planType,
    required this.isPopular,
    this.savings,
  });

  final String title;
  final double price;
  final String duration;
  final String planType;
  final bool isPopular;
  final double? savings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isPopular ? AppColors.accent : AppColors.divider,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            if (isPopular) const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              Formatters.currency(price),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              duration,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (savings != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Save ${Formatters.currency(savings!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.statusApproved,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              onPressed: user == null
                  ? null
                  : () => context.push(
                        RouteNames.getPaymentInstructionsRoute(
                          AppConstants.paymentTypeVip,
                          planType,
                        ),
                      ),
              text: 'Subscribe',
              icon: Icons.star,
            ),
          ],
        ),
      ),
    );
  }
}

/// VIP benefits list widget.
class VipBenefitsList extends StatelessWidget {
  const VipBenefitsList({super.key});

  @override
  Widget build(BuildContext context) {
    const benefits = [
      Icons.lock_open,
      Icons.update,
      Icons.star_border,
      Icons.support_agent,
    ];
    const labels = [
      'Unlock all early-access chapters',
      'Read new chapters before public release',
      'Exclusive VIP badge on your profile',
      'Priority support',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < benefits.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(benefits[i], color: AppColors.accent, size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        labels[i],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// VIP status card for active subscribers.
class VipStatusCard extends StatelessWidget {
  const VipStatusCard({super.key, required this.expiry});

  final DateTime expiry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const Icon(Icons.star, color: AppColors.accent, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIP Active',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Expires: ${Formatters.date(expiry)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
