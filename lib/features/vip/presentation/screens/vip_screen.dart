import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../payments/providers/payments_providers.dart';
import '../widgets/vip_plan_card.dart';

/// VIP subscription screen with plan selection.
class VipScreen extends ConsumerStatefulWidget {
  const VipScreen({super.key});

  @override
  ConsumerState<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends ConsumerState<VipScreen> {
  String _selectedPlan = AppConstants.vipPlanMonthly;
  bool _isOpeningCheckout = false;

  Future<void> _openCheckout() async {
    if (_isOpeningCheckout) return;
    setState(() => _isOpeningCheckout = true);
    try {
      await context.push(
        RouteNames.getPaymentInstructionsRoute(
          AppConstants.paymentTypeVip,
          _selectedPlan,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningCheckout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final userAsync = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('VIP Subscription')),
      body: userAsync.when(
        loading: () => const LoadingView(message: 'Loading...'),
        error: (error, _) => Center(child: Text('Error: ${error.toString()}')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user.isVipActive) ...[
                  VipStatusCard(expiry: user.vipExpiry!),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Hero
                const _VipHero(),
                const SizedBox(height: AppSpacing.xl),

                // Benefits
                const VipBenefitsList(),
                const SizedBox(height: AppSpacing.xl),

                // Plans
                Text(
                  'Choose Your Plan',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                if (settingsAsync.hasError)
                  Text(
                    'Could not load custom prices. Showing standard prices.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                _VipPlanOption(
                  title: 'Monthly VIP Pass',
                  price:
                      settingsAsync.value?.vipMonthlyPrice ??
                      AppConstants.defaultVipMonthlyPrice,
                  detail: ' / month',
                  selected: _selectedPlan == AppConstants.vipPlanMonthly,
                  onTap: () => setState(
                    () => _selectedPlan = AppConstants.vipPlanMonthly,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _VipPlanOption(
                  title: 'Yearly VIP Pass (Best Value!)',
                  price:
                      settingsAsync.value?.vipYearlyPrice ??
                      AppConstants.defaultVipYearlyPrice,
                  detail:
                      ' / year (Save ${_yearlySavingsPercent(settingsAsync.value?.vipMonthlyPrice ?? AppConstants.defaultVipMonthlyPrice, settingsAsync.value?.vipYearlyPrice ?? AppConstants.defaultVipYearlyPrice)}%)',
                  selected: _selectedPlan == AppConstants.vipPlanYearly,
                  onTap: () => setState(
                    () => _selectedPlan = AppConstants.vipPlanYearly,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  onPressed: _isOpeningCheckout ? null : _openCheckout,
                  text: 'Get VIP Pass Now',
                  icon: Icons.star,
                  isLoading: _isOpeningCheckout,
                ),
                if (settingsAsync.value == null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ask the admin for payment details before sending payment.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  int _yearlySavingsPercent(double monthly, double yearly) {
    final monthlyCost = monthly * 12;
    if (monthlyCost <= 0 || yearly >= monthlyCost) return 0;
    return ((monthlyCost - yearly) / monthlyCost * 100).ceil();
  }
}

class _VipPlanOption extends StatelessWidget {
  const _VipPlanOption({
    required this.title,
    required this.price,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final double price;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.divider,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '₱${price.toStringAsFixed(2)}$detail',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// VIP hero section.
class _VipHero extends StatelessWidget {
  const _VipHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star, size: 40, color: AppColors.accent),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Hiraya VIP',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Unlock all early-access chapters',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
