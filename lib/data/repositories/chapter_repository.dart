import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/app_constants.dart';
import '../models/chapter_model.dart';
import '../models/chapter_content_model.dart';
import '../models/unlocked_chapter_model.dart';
import '../services/firestore_service.dart';

/// Repository for chapter operations
class ChapterRepository {
  ChapterRepository({required this._firestoreService});

  final FirestoreService _firestoreService;

  /// Gets chapters for a book
  Future<List<ChapterModel>> getChapters(
    String bookId, {
    int limit = AppConstants.chaptersPerPage,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestoreService.chapters(bookId).orderBy('number');

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      if (limit > 0) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) => ChapterModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
              bookId,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get chapters: ${e.toString()}');
    }
  }

  /// Gets a specific chapter
  Future<ChapterModel?> getChapter(String bookId, String chapterId) async {
    try {
      final doc = await _firestoreService.chapters(bookId).doc(chapterId).get();

      if (!doc.exists) return null;

      return ChapterModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
        bookId,
      );
    } catch (e) {
      throw Exception('Failed to get chapter: ${e.toString()}');
    }
  }

  /// Gets chapter content
  Future<ChapterContentModel?> getChapterContent(String chapterId) async {
    try {
      final doc = await _firestoreService.chapterContents.doc(chapterId).get();

      if (!doc.exists) return null;

      return ChapterContentModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Failed to get chapter content: ${e.toString()}');
    }
  }

  /// Creates a new chapter (admin only)
  Future<String> createChapter(String bookId, ChapterModel chapter) async {
    try {
      final docRef = await _firestoreService
          .chapters(bookId)
          .add(chapter.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create chapter: ${e.toString()}');
    }
  }

  /// Updates a chapter (admin only)
  Future<void> updateChapter(
    String bookId,
    String chapterId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestoreService.chapters(bookId).doc(chapterId).update(updates);
    } catch (e) {
      throw Exception('Failed to update chapter: ${e.toString()}');
    }
  }

  /// Creates or updates chapter content (admin only)
  Future<void> setChapterContent(ChapterContentModel content) async {
    try {
      await _firestoreService.chapterContents
          .doc(content.chapterId)
          .set(content.toMap());
    } catch (e) {
      throw Exception('Failed to set chapter content: ${e.toString()}');
    }
  }

  /// Deletes a chapter (admin only)
  Future<void> deleteChapter(String bookId, String chapterId) async {
    try {
      await _firestoreService.executeBatch((batch) async {
        // Delete chapter document
        batch.delete(_firestoreService.chapters(bookId).doc(chapterId));

        // Delete chapter content
        batch.delete(_firestoreService.chapterContents.doc(chapterId));

        // Note: Also need to delete related unlocked chapters
        // This would require querying first, which can't be done in a batch
      });
    } catch (e) {
      throw Exception('Failed to delete chapter: ${e.toString()}');
    }
  }

  /// Checks if user can access chapter content
  /// Returns true if: chapter is free, user has VIP, or user purchased chapter
  Future<bool> canUserAccessChapter(
    String userId,
    ChapterModel chapter, {
    bool isVipActive = false,
  }) async {
    try {
      // Free chapters (released and not early access)
      if (chapter.isFree) return true;

      // VIP users can access all released chapters
      if (isVipActive && chapter.isReleased) return true;

      // Check if user purchased this specific chapter
      final snapshot = await _firestoreService.unlockedChapters
          .where('userId', isEqualTo: userId)
          .where('chapterId', isEqualTo: chapter.id)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check chapter access: ${e.toString()}');
    }
  }

  /// Gets user's unlocked chapters for a book
  Future<List<String>> getUserUnlockedChapters(
    String userId,
    String bookId,
  ) async {
    try {
      final snapshot = await _firestoreService.unlockedChapters
          .where('userId', isEqualTo: userId)
          .where('bookId', isEqualTo: bookId)
          .get();

      final unlockedChapterIds = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final chapterId = data?['chapterId'] as String?;
        final paymentId = data?['paymentId'] as String?;
        if (chapterId == null ||
            paymentId == null ||
            doc.id != '${userId}_$chapterId' ||
            data?['userId'] != userId ||
            data?['bookId'] != bookId) {
          continue;
        }

        final paymentDoc = await _firestoreService.payments
            .doc(paymentId)
            .get();
        final payment = paymentDoc.data() as Map<String, dynamic>?;
        if (payment != null &&
            payment['userId'] == userId &&
            payment['bookId'] == bookId &&
            payment['type'] == AppConstants.paymentTypeChapter &&
            payment['targetId'] == chapterId &&
            payment['status'] == AppConstants.paymentStatusApproved) {
          unlockedChapterIds.add(chapterId);
        }
      }
      return unlockedChapterIds;
    } catch (e) {
      throw Exception('Failed to get unlocked chapters: ${e.toString()}');
    }
  }

  /// Creates the canonical unlock record for an approved payment.
  Future<void> recordApprovedUnlock(UnlockedChapterModel unlock) async {
    try {
      final doc = _firestoreService.unlockedChapters.doc(unlock.id);
      final existing = await doc.get();
      if (existing.exists) return;
      await doc.set(unlock.toMap());
    } catch (e) {
      throw Exception(
        'Failed to record approved chapter unlock: ${e.toString()}',
      );
    }
  }

  /// Creates an unlocked chapter record (when payment is approved)
  Future<void> unlockChapter(UnlockedChapterModel unlockedChapter) async {
    try {
      await _firestoreService.unlockedChapters.add(unlockedChapter.toMap());
    } catch (e) {
      throw Exception('Failed to unlock chapter: ${e.toString()}');
    }
  }

  /// Gets released chapters for a book
  Future<List<ChapterModel>> getReleasedChapters(String bookId) async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestoreService
          .chapters(bookId)
          .where('releaseDate', isLessThanOrEqualTo: now)
          .orderBy('releaseDate')
          .orderBy('number')
          .get();

      return snapshot.docs
          .map(
            (doc) => ChapterModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
              bookId,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get released chapters: ${e.toString()}');
    }
  }

  /// Gets upcoming chapters (not yet released)
  Future<List<ChapterModel>> getUpcomingChapters(String bookId) async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestoreService
          .chapters(bookId)
          .where('releaseDate', isGreaterThan: now)
          .orderBy('releaseDate')
          .orderBy('number')
          .get();

      return snapshot.docs
          .map(
            (doc) => ChapterModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
              bookId,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming chapters: ${e.toString()}');
    }
  }
}
