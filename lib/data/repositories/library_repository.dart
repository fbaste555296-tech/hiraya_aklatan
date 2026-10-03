import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

/// Repository for user library operations (reading progress).
class LibraryRepository {
  LibraryRepository({required this._firestoreService});

  final FirestoreService _firestoreService;

  /// Saves the last read chapter for a user.
  ///
  /// Stores in `libraries/{userId}/books/{bookId}` with the chapter ID
  /// and timestamp for resume-reading functionality.
  Future<void> saveProgress({
    required String userId,
    required String bookId,
    required String chapterId,
  }) async {
    try {
      await _firestoreService.libraryBooks(userId).doc(bookId).set({
        'lastChapterId': chapterId,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save reading progress: ${e.toString()}');
    }
  }

  /// Adds a book to the user's library without changing existing progress.
  Future<void> addBook({
    required String userId,
    required String bookId,
    required String title,
    required String author,
    required String coverUrl,
  }) async {
    try {
      await _firestoreService.libraryBooks(userId).doc(bookId).set({
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'addedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add book to library: ${e.toString()}');
    }
  }

  /// Gets the last read chapter ID for a user.
  Future<String?> getLastChapterId(String userId, String bookId) async {
    try {
      final doc = await _firestoreService
          .libraryBooks(userId)
          .doc(bookId)
          .get();
      if (!doc.exists) return null;
      return (doc.data() as Map<String, dynamic>?)?['lastChapterId'] as String?;
    } catch (e) {
      throw Exception('Failed to get reading progress: ${e.toString()}');
    }
  }

  /// Checks if a book has been added to the user's library.
  Future<bool> containsBook(String userId, String bookId) async {
    try {
      final doc = await _firestoreService
          .libraryBooks(userId)
          .doc(bookId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check library book: ${e.toString()}');
    }
  }

  /// Gets all books in the user's library with reading progress.
  Future<List<Map<String, dynamic>>> getUserLibrary(String userId) async {
    try {
      final snapshot = await _firestoreService.libraryBooks(userId).get();
      final items = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final bookSnapshot = await _firestoreService.books.doc(doc.id).get();
        final bookData = bookSnapshot.data() as Map<String, dynamic>?;
        final updatedAt = data['updatedAt'];
        final addedAt = data['addedAt'];

        items.add({
          ...data,
          'title': bookData?['title'] ?? data['title'] ?? doc.id,
          'author': bookData?['author'] ?? data['author'] ?? '',
          'coverUrl': bookData?['coverUrl'] ?? data['coverUrl'] ?? '',
          'bookId': doc.id,
          if (updatedAt is Timestamp) 'updatedAt': updatedAt.toDate(),
          if (addedAt is Timestamp) 'addedAt': addedAt.toDate(),
        });
      }
      return items;
    } catch (e) {
      throw Exception('Failed to get user library: ${e.toString()}');
    }
  }

  /// Removes a book from the user's library.
  Future<void> removeFromLibrary({
    required String userId,
    required String bookId,
  }) async {
    try {
      await _firestoreService.libraryBooks(userId).doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to remove from library: ${e.toString()}');
    }
  }
}
