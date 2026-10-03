import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/book_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/providers/service_providers.dart';

/// Provider for a single book's details.
final bookDetailsProvider =
    FutureProvider.family<BookModel?, String>((ref, bookId) async {
  final repository = ref.watch(bookRepositoryProvider);
  final book = await repository.getBookById(bookId);

  if (book == null) return null;

  // Optimize cover URL for the detail view (larger size).
  final cloudinary = ref.read(cloudinaryServiceProvider);
  return book.copyWith(
    coverUrl: cloudinary.getCoverUrl(book.coverUrl, width: 600),
  );
});

/// Provider for the signed-in user's rating for a book.
final userBookRatingProvider =
    FutureProvider.family<int?, ({String bookId, String userId})>(
        (ref, params) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getUserRating(
    bookId: params.bookId,
    userId: params.userId,
  );
});

/// Provider for the chapter list of a book.
final chaptersProvider =
    FutureProvider.family<List<ChapterModel>, String>((ref, bookId) async {
  final repository = ref.watch(chapterRepositoryProvider);
  return repository.getChapters(bookId);
});
