import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../models/payment_model.dart';
import '../models/unlocked_chapter_model.dart';
import '../services/firestore_service.dart';

/// Repository for payment operations
class PaymentRepository {
  PaymentRepository({required this._firestoreService});

  final FirestoreService _firestoreService;

  /// Creates a new payment request
  Future<String> createPayment(PaymentModel payment) async {
    try {
      final docRef = await _firestoreService.payments.add(payment.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create payment: ${e.toString()}');
    }
  }

  /// Gets user's payment history
  Future<List<PaymentModel>> getUserPayments(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestoreService.payments
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user payments: ${e.toString()}');
    }
  }

  /// Finds an approved chapter payment owned by a user.
  Future<PaymentModel?> getApprovedChapterPayment({
    required String userId,
    required String chapterId,
  }) async {
    try {
      final snapshot = await _firestoreService.payments
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in snapshot.docs) {
        final payment = PaymentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        if (payment.type == AppConstants.paymentTypeChapter &&
            payment.status == AppConstants.paymentStatusApproved &&
            payment.targetId == chapterId) {
          return payment;
        }
      }
      return null;
    } catch (e) {
      throw Exception(
        'Failed to find approved chapter payment: ${e.toString()}',
      );
    }
  }

  /// Gets payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestoreService.payments.doc(paymentId).get();

      if (!doc.exists) return null;

      return PaymentModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Failed to get payment: ${e.toString()}');
    }
  }

  /// Gets pending payments (admin only)
  Future<List<PaymentModel>> getPendingPayments({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestoreService.payments
          .where('status', isEqualTo: AppConstants.paymentStatusPending)
          .orderBy('createdAt');

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending payments: ${e.toString()}');
    }
  }

  /// Approves a payment and unlocks content (admin only).
  ///
  /// This is a critical operation that must be atomic — all writes happen
  /// in a single batched write.
  ///
  /// For chapter payments: creates an unlockedChapters record with
  /// document ID `{userId}_{chapterId}` (required by firestore.rules).
  ///
  /// For VIP payments: extends the user's vipExpiry by the plan duration,
  /// starting from the current expiry if still active, or from now if expired.
  Future<void> approvePayment(String paymentId) async {
    try {
      await _firestoreService.executeBatch((batch) async {
        final paymentDoc = _firestoreService.payments.doc(paymentId);
        final payment = await getPaymentById(paymentId);

        if (payment == null) {
          throw Exception('Payment not found');
        }

        if (payment.status != AppConstants.paymentStatusPending) {
          throw Exception('Payment is not pending');
        }

        // Update payment status
        batch.update(paymentDoc, {
          'status': AppConstants.paymentStatusApproved,
          'reviewedAt': _firestoreService.now,
        });

        if (payment.type == AppConstants.paymentTypeChapter) {
          // Unlock specific chapter
          if (payment.targetId != null && payment.bookId != null) {
            // Use userId_chapterId format for document ID (required by firestore.rules)
            final unlockedDocId = '${payment.userId}_${payment.targetId}';
            final unlockedDoc =
                _firestoreService.unlockedChapters.doc(unlockedDocId);

            final unlockedChapter = UnlockedChapterModel(
              id: unlockedDocId,
              userId: payment.userId,
              bookId: payment.bookId!,
              chapterId: payment.targetId!,
              paymentId: paymentId,
              unlockedAt: DateTime.now(),
            );

            batch.set(unlockedDoc, unlockedChapter.toMap());
          }
        } else if (payment.type == AppConstants.paymentTypeVip) {
          // Update user's VIP expiry
          final userDoc = _firestoreService.users.doc(payment.userId);

          // Calculate new expiry date
          final now = DateTime.now();
          int daysToAdd = 0;

          if (payment.planType == AppConstants.vipPlanMonthly) {
            daysToAdd = AppConstants.vipMonthlyDays;
          } else if (payment.planType == AppConstants.vipPlanYearly) {
            daysToAdd = AppConstants.vipYearlyDays;
          }

          // Get current user to check if VIP is still active
          final userSnapshot = await userDoc.get();
          DateTime baseDate = now;

          if (userSnapshot.exists) {
            final userData = userSnapshot.data() as Map<String, dynamic>?;
            final currentExpiry = userData?['vipExpiry'] as Timestamp?;
            if (currentExpiry != null) {
              final currentExpiryDate = currentExpiry.toDate();
              if (currentExpiryDate.isAfter(now)) {
                // VIP still active — extend from current expiry
                baseDate = currentExpiryDate;
              }
            }
          }

          final newExpiry = baseDate.add(Duration(days: daysToAdd));

          batch.update(userDoc, {
            'vipExpiry': Timestamp.fromDate(newExpiry),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to approve payment: ${e.toString()}');
    }
  }

  /// Rejects a payment (admin only)
  Future<void> rejectPayment(String paymentId, String adminNote) async {
    try {
      await _firestoreService.payments.doc(paymentId).update({
        'status': AppConstants.paymentStatusRejected,
        'adminNote': adminNote,
        'reviewedAt': _firestoreService.now,
      });
    } catch (e) {
      throw Exception('Failed to reject payment: ${e.toString()}');
    }
  }

  /// Generates a unique reference code
  String generateReferenceCode() {
    return Formatters.generateReferenceCode();
  }

  /// Checks if reference number already exists
  Future<bool> isReferenceNumberUsed(String referenceNo) async {
    try {
      final snapshot = await _firestoreService.payments
          .where('referenceNo', isEqualTo: referenceNo)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check reference number: ${e.toString()}');
    }
  }

  /// Gets payment statistics (admin only)
  Future<Map<String, int>> getPaymentStats() async {
    try {
      final pending = await _firestoreService.payments
          .where('status', isEqualTo: AppConstants.paymentStatusPending)
          .count()
          .get();

      final approved = await _firestoreService.payments
          .where('status', isEqualTo: AppConstants.paymentStatusApproved)
          .count()
          .get();

      final rejected = await _firestoreService.payments
          .where('status', isEqualTo: AppConstants.paymentStatusRejected)
          .count()
          .get();

      return {
        'pending': pending.count ?? 0,
        'approved': approved.count ?? 0,
        'rejected': rejected.count ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to get payment stats: ${e.toString()}');
    }
  }

  /// Gets recent payments (admin only)
  Future<List<PaymentModel>> getRecentPayments({int limit = 20}) async {
    try {
      final snapshot = await _firestoreService.payments
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent payments: ${e.toString()}');
    }
  }
}