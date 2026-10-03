import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_constants.dart';
import '../models/book_model.dart';
import '../services/firestore_service.dart';

/// Result of a book query including pagination cursor.
class BookQueryResult {
  const BookQueryResult({
    required this.books,
    required this.lastDocument,
  });

  final List<BookModel> books;
  final DocumentSnapshot? lastDocument;
}

/// Repository for book data operations
class BookRepository {
  BookRepository({required this._firestoreService});

  final FirestoreService _firestoreService;

  /// Gets all books with pagination and filtering.
  /// Returns a [BookQueryResult] containing the books and the last document
  /// snapshot for cursor-based pagination.
  Future<BookQueryResult> getBooks({
    int limit = AppConstants.booksPerPage,
    DocumentSnapshot? startAfter,
    String? genre,
    String? searchTerm,
    String orderBy = 'createdAt',
    bool descending = true,
  }) async {
    try {
      Query query = _firestoreService.books;

      // Apply genre filter
      if (genre != null && genre.isNotEmpty) {
        query = query.where('genres', arrayContains: genre);
      }

      // Apply search (title or author)
      if (searchTerm != null && searchTerm.isNotEmpty) {
        // Note: Firestore doesn't support full-text search
        // This is a simple implementation - consider using Algolia for production
        query = query
            .where('title', isGreaterThanOrEqualTo: searchTerm)
            .where('title', isLessThan: '${searchTerm}z');
      }

      // Apply ordering
      query = query.orderBy(orderBy, descending: descending);

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      final books = snapshot.docs
          .map((doc) => BookModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      return BookQueryResult(
        books: books,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      throw Exception('Failed to get books: ${e.toString()}');
    }
  }

  /// Gets a book by ID
  Future<BookModel?> getBookById(String bookId) async {
    try {
      final doc = await _firestoreService.books.doc(bookId).get();

      if (!doc.exists) return null;

      return BookModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Failed to get book: ${e.toString()}');
    }
  }

  /// Stream of book data
  Stream<BookModel?> watchBook(String bookId) {
    return _firestoreService.books.doc(bookId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BookModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  /// Creates a new book (admin only)
  Future<String> createBook(BookModel book) async {
    try {
      final docRef = await _firestoreService.books.add(book.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create book: ${e.toString()}');
    }
  }

  /// Updates a book (admin only)
  Future<void> updateBook(String bookId, Map<String, dynamic> updates) async {
    try {
      await _firestoreService.books.doc(bookId).update(updates);
    } catch (e) {
      throw Exception('Failed to update book: ${e.toString()}');
    }
  }

  /// Deletes a book (admin only)
  Future<void> deleteBook(String bookId) async {
    try {
      await _firestoreService.books.doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: ${e.toString()}');
    }
  }

  /// Gets the current user's rating for a book, if they have rated it.
  Future<int?> getUserRating({
    required String bookId,
    required String userId,
  }) async {
    try {
      final snapshot =
          await _firestoreService.bookRatings(bookId).doc(userId).get();
      if (!snapshot.exists) return null;
      return (snapshot.data() as Map<String, dynamic>)['rating'] as int;
    } catch (e) {
      throw Exception('Failed to get your book rating: ${e.toString()}');
    }
  }

  /// Creates or replaces a user's rating and atomically updates the average.
  Future<void> rateBook({
    required String bookId,
    required String userId,
    required int rating,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 5');
    }

    try {
      final bookRef = _firestoreService.books.doc(bookId);
      final ratingRef = _firestoreService.bookRatings(bookId).doc(userId);
      await _firestoreService.runTransaction((transaction) async {
        final bookSnapshot = await transaction.get(bookRef);
        if (!bookSnapshot.exists) {
          throw StateError('Book not found.');
        }

        final previousRatingSnapshot = await transaction.get(ratingRef);
        final bookData = bookSnapshot.data() as Map<String, dynamic>;
        final ratingCount =
            (bookData['ratingCount'] as num?)?.toInt() ?? 0;
        final averageRating = (bookData['rating'] as num?)?.toDouble() ?? 0;
        final previousRating = previousRatingSnapshot.exists
            ? (previousRatingSnapshot.data() as Map<String, dynamic>)['rating']
                as int
            : null;
        final updatedCount = previousRating == null
            ? ratingCount + 1
            : (ratingCount > 0 ? ratingCount : 1);
        final existingAverage = ratingCount > 0
            ? averageRating
            : (previousRating?.toDouble() ?? 0);
        final existingCount = ratingCount > 0
            ? ratingCount
            : (previousRating == null ? 0 : 1);
        final updatedAverage =
            (existingAverage * existingCount -
                    (previousRating ?? 0) +
                    rating) /
                updatedCount;

        transaction.set(ratingRef, {
          'userId': userId,
          'rating': rating,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(bookRef, {
          'rating': updatedAverage,
          'ratingCount': updatedCount,
        });
      });
    } catch (e) {
      throw Exception('Failed to save book rating: ${e.toString()}');
    }
  }

  /// Gets books by genre
  Future<List<BookModel>> getBooksByGenre(String genre, {int limit = 20}) async {
    try {
      final snapshot = await _firestoreService.books
          .where('genres', arrayContains: genre)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => BookModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get books by genre: ${e.toString()}');
    }
  }

  /// Gets featured/popular books
  Future<List<BookModel>> getFeaturedBooks({int limit = 10}) async {
    try {
      final snapshot = await _firestoreService.books
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => BookModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get featured books: ${e.toString()}');
    }
  }

  /// Gets recently added books
  Future<List<BookModel>> getRecentBooks({int limit = 10}) async {
    try {
      final snapshot = await _firestoreService.books
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => BookModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent books: ${e.toString()}');
    }
  }

}