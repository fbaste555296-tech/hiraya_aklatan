import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hiraya_aklatan/core/config/app_constants.dart';

void main() {
  group('VIP expiry calculation', () {
    test('monthly plan adds 30 days from now when VIP expired', () {
      final now = DateTime.now();
      final expiredVip = now.subtract(const Duration(days: 10));

      final baseDate = expiredVip.isAfter(now) ? expiredVip : now;
      final newExpiry = baseDate.add(const Duration(days: AppConstants.vipMonthlyDays));

      final expectedExpiry = now.add(const Duration(days: 30));
      expect(newExpiry.difference(expectedExpiry).inDays.abs(), lessThan(1));
    });

    test('yearly plan adds 365 days from now when VIP expired', () {
      final now = DateTime.now();
      final expiredVip = now.subtract(const Duration(days: 10));

      final baseDate = expiredVip.isAfter(now) ? expiredVip : now;
      final newExpiry = baseDate.add(const Duration(days: AppConstants.vipYearlyDays));

      final expectedExpiry = now.add(const Duration(days: 365));
      expect(newExpiry.difference(expectedExpiry).inDays.abs(), lessThan(1));
    });

    test('monthly plan extends from current expiry when VIP still active', () {
      final now = DateTime.now();
      final activeVipExpiry = now.add(const Duration(days: 15));

      final baseDate = activeVipExpiry.isAfter(now) ? activeVipExpiry : now;
      final newExpiry = baseDate.add(const Duration(days: AppConstants.vipMonthlyDays));

      final expectedExpiry = activeVipExpiry.add(const Duration(days: 30));
      expect(newExpiry.difference(expectedExpiry).inDays.abs(), lessThan(1));
    });

    test('yearly plan extends from current expiry when VIP still active', () {
      final now = DateTime.now();
      final activeVipExpiry = now.add(const Duration(days: 200));

      final baseDate = activeVipExpiry.isAfter(now) ? activeVipExpiry : now;
      final newExpiry = baseDate.add(const Duration(days: AppConstants.vipYearlyDays));

      final expectedExpiry = activeVipExpiry.add(const Duration(days: 365));
      expect(newExpiry.difference(expectedExpiry).inDays.abs(), lessThan(1));
    });

    test('stacking monthly plans accumulates correctly', () {
      final now = DateTime.now();
      final activeVipExpiry = now.add(const Duration(days: 20));

      // First approval: extend by 30 days
      final firstExpiry = activeVipExpiry.add(const Duration(days: 30));
      // Second approval: extend by another 30 days
      final secondExpiry = firstExpiry.add(const Duration(days: 30));

      final expectedExpiry = now.add(const Duration(days: 80));
      expect(secondExpiry.difference(expectedExpiry).inDays.abs(), lessThan(1));
    });
  });

  group('Unlocked chapter document ID format', () {
    test('document ID uses userId_chapterId format', () {
      const userId = 'user123';
      const chapterId = 'chapter456';

      final docId = '${userId}_$chapterId';

      expect(docId, 'user123_chapter456');
      expect(docId.contains('_'), isTrue);
      expect(docId.startsWith(userId), isTrue);
      expect(docId.endsWith(chapterId), isTrue);
    });

    test('document ID is unique per user and chapter', () {
      final docId1 = 'user1_chapter1';
      final docId2 = 'user1_chapter2';
      final docId3 = 'user2_chapter1';

      expect(docId1, isNot(equals(docId2)));
      expect(docId1, isNot(equals(docId3)));
      expect(docId2, isNot(equals(docId3)));
    });
  });

  group('Payment status constants', () {
    test('pending status is correct', () {
      expect(AppConstants.paymentStatusPending, 'pending');
    });

    test('approved status is correct', () {
      expect(AppConstants.paymentStatusApproved, 'approved');
    });

    test('rejected status is correct', () {
      expect(AppConstants.paymentStatusRejected, 'rejected');
    });
  });

  group('VIP plan constants', () {
    test('monthly plan days is 30', () {
      expect(AppConstants.vipMonthlyDays, 30);
    });

    test('yearly plan days is 365', () {
      expect(AppConstants.vipYearlyDays, 365);
    });

    test('monthly plan type is correct', () {
      expect(AppConstants.vipPlanMonthly, 'monthly');
    });

    test('yearly plan type is correct', () {
      expect(AppConstants.vipPlanYearly, 'yearly');
    });
  });
}
