import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/book_repository.dart';
import '../repositories/chapter_repository.dart';
import '../repositories/library_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/user_repository.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';

/// Shared provider for the Firestore service.
///
/// Kept in the data layer so both the router and feature providers can
/// depend on it without circular imports.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Shared provider for the Cloudinary service.
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService.instance;
});

/// Shared provider for the user repository.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return UserRepository(firestoreService: firestoreService);
});

/// Shared provider for the book repository.
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BookRepository(firestoreService: firestoreService);
});

/// Shared provider for the chapter repository.
final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ChapterRepository(firestoreService: firestoreService);
});

/// Shared provider for the library repository (reading progress).
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return LibraryRepository(firestoreService: firestoreService);
});

/// Shared provider for the payment repository.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PaymentRepository(firestoreService: firestoreService);
});

/// Shared provider for the settings repository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return SettingsRepository(firestoreService: firestoreService);
});
