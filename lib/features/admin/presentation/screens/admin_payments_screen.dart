import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/models/payment_model.dart';
import '../../../../data/providers/service_providers.dart';
import '../../providers/admin_providers.dart';

/// Admin screen for reviewing and approving/rejecting payments.
class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(adminPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Main Menu',
          onPressed: () => context.go(RouteNames.library),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'App Settings',
            onPressed: () => context.push(RouteNames.adminSettings),
          ),
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: 'Manage Books',
            onPressed: () => context.push(RouteNames.adminBooks),
          ),
        ],
      ),
      body: paymentsAsync.when(
        loading: () => const LoadingView(message: 'Loading payments...'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(adminPaymentsProvider),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return const EmptyView(
              icon: Icons.check_circle,
              message: 'No pending payments. All caught up!',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Pending Payment Review (${payments.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _PaymentReviewCard(payment: payment);
                  },
                ),
              ),
            ],
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

/// Card displaying a payment for admin review.
class _PaymentReviewCard extends ConsumerStatefulWidget {
  const _PaymentReviewCard({required this.payment});

  final PaymentModel payment;

  @override
  ConsumerState<_PaymentReviewCard> createState() => _PaymentReviewCardState();
}

class _PaymentReviewCardState extends ConsumerState<_PaymentReviewCard> {
  bool _isProcessing = false;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.approvePayment(widget.payment.id);

      if (mounted) {
        ref.invalidate(adminPaymentsProvider);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Payment approved.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _reject() async {
    _noteController.clear();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter a note for the customer',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _noteController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (!mounted || note == null) return;
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a rejection note.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.rejectPayment(widget.payment.id, note);

      if (mounted) {
        ref.invalidate(adminPaymentsProvider);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Payment rejected.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ref
                      .watch(paymentSubmitterProvider(widget.payment.userId))
                      .when(
                        loading: () => Text(
                          'Loading customer...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        error: (error, _) => Text(
                          'User: ${widget.payment.userId}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        data: (user) => Text(
                          'User: ${user?.email.isNotEmpty == true ? user!.email : widget.payment.userId}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            Text(
              'Type: ${_getTypeLabel()} (${Formatters.currency(widget.payment.amount)})',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.primary),
            ),
            _DetailRow(label: 'Ref No:', value: widget.payment.referenceNo),
            _DetailRow(label: 'Ref Code:', value: widget.payment.referenceCode),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _showReceipt,
              child: Container(
                height: 120,
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Text(
                  'View Receipt Proof',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Action buttons
            const SizedBox(height: AppSpacing.md),
            if (!_isProcessing)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _approve,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.statusApproved,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _reject,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel() {
    if (widget.payment.type == AppConstants.paymentTypeVip) {
      return 'VIP - ${widget.payment.planType == AppConstants.vipPlanMonthly ? 'Monthly' : 'Yearly'}';
    }
    return 'Chapter Unlock';
  }

  void _showReceipt() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            widget.payment.proofUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Icon(Icons.broken_image_outlined, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row displaying a label-value pair.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
