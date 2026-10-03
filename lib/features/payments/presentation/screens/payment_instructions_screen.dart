import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/models/app_settings_model.dart';
import '../../../../data/models/payment_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/payments_providers.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/receipt_upload_widget.dart';

/// Payment instruction screen for chapter unlock and VIP subscription.
class PaymentInstructionsScreen extends ConsumerStatefulWidget {
  const PaymentInstructionsScreen({
    super.key,
    required this.type,
    required this.targetId,
    this.planType,
    this.chapterBookId,
  });

  final String type; // 'chapter' or 'vip'
  final String targetId; // chapterId or planType
  final String? planType; // 'monthly' or 'yearly' for VIP
  final String? chapterBookId;

  @override
  ConsumerState<PaymentInstructionsScreen> createState() =>
      _PaymentInstructionsScreenState();
}

class _PaymentAccountTile extends StatelessWidget {
  const _PaymentAccountTile({required this.name, required this.number});

  final String name;
  final String number;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_outlined),
        title: Text(name),
        subtitle: Text(number),
      ),
    );
  }
}

class _PaymentInstructionsScreenState
    extends ConsumerState<PaymentInstructionsScreen> {
  String? _receiptUrl;
  bool _isSubmitting = false;

  Future<void> _submitPayment() async {
    if (_isSubmitting) return;
    if (_receiptUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your receipt first.')),
      );
      return;
    }
    final user = ref.read(firebaseUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit payment.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final instructions = await ref.read(paymentInstructionsProvider((
        type: widget.type,
        targetId: widget.targetId,
        planType: widget.planType,
        bookId: widget.chapterBookId,
      )).future);

      final payment = PaymentModel(
        id: '',
        userId: user.uid,
        type: widget.type,
        targetId: widget.targetId,
        bookId: instructions.bookId,
        planType: widget.type == AppConstants.paymentTypeVip
            ? instructions.planType
            : null,
        amount: instructions.amount,
        referenceCode: instructions.referenceCode,
        referenceNo: 'RECEIPT-${DateTime.now().microsecondsSinceEpoch}',
        proofUrl: _receiptUrl!,
        status: AppConstants.paymentStatusPending,
        createdAt: DateTime.now(),
      );
      await ref.read(submitPaymentProvider(payment).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment submitted for review.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructionsAsync = ref.watch(paymentInstructionsProvider((
      type: widget.type,
      targetId: widget.targetId,
      planType: widget.planType,
      bookId: widget.chapterBookId,
    )));

    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == AppConstants.paymentTypeChapter
              ? 'Unlock Chapter'
              : 'Get VIP',
        ),
      ),
      body: instructionsAsync.when(
        loading: () => const LoadingView(message: 'Loading payment details...'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(
            paymentInstructionsProvider((
              type: widget.type,
              targetId: widget.targetId,
              planType: widget.planType,
              bookId: widget.chapterBookId,
            )),
          ),
        ),
        data: (instructions) => _buildContent(context, instructions, settingsAsync),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PaymentInstructions instructions,
    AsyncValue<AppSettingsModel?> settingsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountCard(amount: instructions.amount),
            const SizedBox(height: AppSpacing.lg),

            ReferenceCodeCard(referenceCode: instructions.referenceCode),
            const SizedBox(height: AppSpacing.lg),

            if (settingsAsync.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  'Could not load payment instructions: '
                  '${_friendlyError(settingsAsync.error!)}',
                ),
              )
            else if (settingsAsync.value == null)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  'Payment instructions are not configured yet. Contact the admin '
                  'before sending payment. You can still submit your receipt for review.',
                ),
              )
            else ...[
              if (settingsAsync.value!.gcashNumber.isNotEmpty)
                _PaymentAccountTile(
                  name: 'GCash',
                  number: settingsAsync.value!.gcashNumber,
                ),
              if (settingsAsync.value!.mayaNumber.isNotEmpty)
                _PaymentAccountTile(
                  name: 'Maya',
                  number: settingsAsync.value!.mayaNumber,
                ),
              if (settingsAsync.value!.qrUrl.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Text(
                          'Scan QR Code',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: Image.network(
                            settingsAsync.value!.qrUrl,
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.qr_code, size: 200),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],

            Text(
              'Upload Receipt',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ReceiptUploadWidget(
              onUploaded: (url) => setState(() => _receiptUrl = url),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              onPressed: _isSubmitting ? null : _submitPayment,
              text: 'Submit Payment Proof',
              icon: Icons.send,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Your payment will be reviewed by our team. This usually takes 24 hours.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
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
