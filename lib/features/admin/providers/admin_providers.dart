import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_settings_model.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/service_providers.dart';

/// Dashboard statistics for the admin overview.
class AdminStats {
  const AdminStats({
    this.totalBooks = 0,
    this.totalUsers = 0,
    this.pendingPayments = 0,
    this.vipUsers = 0,
  });

  final int totalBooks;
  final int totalUsers;
  final int pendingPayments;
  final int vipUsers;
}

/// Provider for admin dashboard statistics.
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final bookRepository = ref.watch(bookRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final paymentRepository = ref.watch(paymentRepositoryProvider);

  final booksResult = await bookRepository.getBooks(limit: 1000);
  final users = await userRepository.getAllUsers(limit: 1000);
  final pendingPayments = await paymentRepository.getPendingPayments(limit: 1000);
  final vipUsersCount = await userRepository.getVipUsersCount();

  return AdminStats(
    totalBooks: booksResult.books.length,
    totalUsers: users.length,
    pendingPayments: pendingPayments.length,
    vipUsers: vipUsersCount,
  );
});

/// Provider for admin book list.
final adminBooksProvider = FutureProvider<List<BookModel>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  final result = await repository.getBooks(limit: 1000);
  return result.books;
});

/// Provider for admin chapter list.
final adminChaptersProvider =
    FutureProvider.family<List<ChapterModel>, String>((ref, bookId) async {
  final repository = ref.watch(chapterRepositoryProvider);
  return repository.getChapters(bookId);
});

/// Provider for admin pending payments.
final adminPaymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPendingPayments(limit: 100);
});

/// Provider for the user who submitted a payment.
final paymentSubmitterProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUserById(userId);
});

/// Provider for admin settings.
final adminSettingsProvider = FutureProvider<AppSettingsModel?>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getAppSettings();
});

/// Provider for all users (admin).
final adminUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getAllUsers(limit: 1000);
});

/// Provider for creating or updating a book.
final saveBookProvider = FutureProvider.family<void, BookModel>((ref, book) async {
  final repository = ref.watch(bookRepositoryProvider);
  if (book.id.isEmpty) {
    await repository.createBook(book);
  } else {
    await repository.updateBook(book.id, book.toMap());
  }
});

/// Provider for deleting a book.
final deleteBookProvider = FutureProvider.family<void, String>((ref, bookId) async {
  final repository = ref.watch(bookRepositoryProvider);
  await repository.deleteBook(bookId);
});

/// Provider for creating or updating a chapter.
final saveChapterProvider =
    FutureProvider.family<void, ({String bookId, ChapterModel chapter})>(
        (ref, params) async {
  final repository = ref.watch(chapterRepositoryProvider);
  if (params.chapter.id.isEmpty) {
    await repository.createChapter(params.bookId, params.chapter);
  } else {
    await repository.updateChapter(
        params.bookId, params.chapter.id, params.chapter.toMap());
  }
});

/// Provider for deleting a chapter.
final deleteChapterProvider =
    FutureProvider.family<void, ({String bookId, String chapterId})>(
        (ref, params) async {
  final repository = ref.watch(chapterRepositoryProvider);
  await repository.deleteChapter(params.bookId, params.chapterId);
});

/// Provider for approving a payment.
final approvePaymentProvider =
    FutureProvider.family<void, String>((ref, paymentId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  await repository.approvePayment(paymentId);
});

/// Provider for rejecting a payment.
final rejectPaymentProvider =
    FutureProvider.family<void, ({String paymentId, String note})>(
        (ref, params) async {
  final repository = ref.watch(paymentRepositoryProvider);
  await repository.rejectPayment(params.paymentId, params.note);
});

/// Provider for updating app settings.
final updateSettingsProvider =
    FutureProvider.family<void, AppSettingsModel>((ref, settings) async {
  final repository = ref.watch(settingsRepositoryProvider);
  await repository.updateAppSettings(settings);
});
