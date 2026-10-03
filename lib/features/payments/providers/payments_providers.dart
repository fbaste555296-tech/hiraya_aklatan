import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/app_settings_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/providers/service_providers.dart';
import '../../../features/auth/providers/auth_providers.dart';

/// Payment instruction details for a chapter or VIP plan.
class PaymentInstructions {
  const PaymentInstructions({
    required this.type,
    required this.targetId,
    required this.amount,
    required this.referenceCode,
    this.chapter,
    this.bookId,
    this.planType,
  });

  final String type; // 'chapter' or 'vip'
  final String targetId; // chapterId or planType
  final double amount;
  final String referenceCode;
  final ChapterModel? chapter;
  final String? bookId; // bookId for chapter payments
  final String? planType; // 'monthly' or 'yearly' for VIP
}

/// Provider for fetching payment instructions.
final paymentInstructionsProvider =
    FutureProvider.family<
      PaymentInstructions,
      ({String type, String targetId, String? planType, String? bookId})
    >((ref, params) async {
      final settingsRepository = ref.watch(settingsRepositoryProvider);
      final chapterRepository = ref.watch(chapterRepositoryProvider);

      final referenceCode = Formatters.generateReferenceCode();

      if (params.type == AppConstants.paymentTypeChapter) {
        final bookId = params.bookId;
        if (bookId == null || bookId.isEmpty) {
          throw Exception(
            'Book information is missing. Please reopen this chapter.',
          );
        }
        final chapter = await chapterRepository.getChapter(
          bookId,
          params.targetId,
        );
        if (chapter == null) {
          throw Exception('Chapter not found.');
        }

        return PaymentInstructions(
          type: params.type,
          targetId: params.targetId,
          amount: chapter.price,
          referenceCode: referenceCode,
          chapter: chapter,
          bookId: bookId,
        );
      } else {
        final settings = await settingsRepository.getAppSettings();
        final planType = params.planType ?? params.targetId;
        final amount = planType == AppConstants.vipPlanMonthly
            ? settings?.vipMonthlyPrice ?? AppConstants.defaultVipMonthlyPrice
            : settings?.vipYearlyPrice ?? AppConstants.defaultVipYearlyPrice;

        return PaymentInstructions(
          type: params.type,
          targetId: params.targetId,
          amount: amount,
          referenceCode: referenceCode,
          planType: planType,
        );
      }
    });

/// Provider for app settings (payment methods, VIP prices).
final appSettingsProvider = FutureProvider<AppSettingsModel?>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getAppSettings();
});

/// Provider for submitting a payment.
final submitPaymentProvider = FutureProvider.family<void, PaymentModel>((
  ref,
  payment,
) async {
  final repository = ref.watch(paymentRepositoryProvider);
  await repository.createPayment(payment);
});

/// Provider for user's payment history.
final paymentHistoryProvider = FutureProvider<List<PaymentModel>>((ref) async {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return [];

  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getUserPayments(user.uid);
});

/// Provider for checking if a reference number is already used.
final isReferenceNumberUsedProvider = FutureProvider.family<bool, String>((
  ref,
  referenceNo,
) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.isReferenceNumberUsed(referenceNo);
});
