import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../data/models/payment_model.dart';
import '../../providers/payments_providers.dart';

/// Payment history screen showing all user payments with status.
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(paymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: historyAsync.when(
        loading: () => const LoadingView(message: 'Loading payments...'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(paymentHistoryProvider),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long,
              message: 'No payments yet.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _PaymentHistoryCard(payment: payment);
            },
          );
        },
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

/// Card displaying a single payment in the history list.
class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: type + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTypeLabel(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                StatusChip(status: payment.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Amount
            Text(
              Formatters.currency(payment.amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Reference code
            _InfoRow(
              icon: Icons.tag,
              label: 'Reference Code',
              value: payment.referenceCode,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Reference number
            _InfoRow(
              icon: Icons.numbers,
              label: 'Reference No.',
              value: payment.referenceNo,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Date
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: Formatters.dateTime(payment.createdAt),
            ),

            // Admin note (for rejected payments)
            if (payment.status == AppConstants.paymentStatusRejected &&
                payment.adminNote != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Note:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      payment.adminNote!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeLabel() {
    if (payment.type == AppConstants.paymentTypeVip) {
      return 'VIP - ${payment.planType == AppConstants.vipPlanMonthly ? 'Monthly' : 'Yearly'}';
    }
    return 'Chapter Unlock';
  }
}

/// Row with icon, label, and value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
