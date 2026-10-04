import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/chapter_access.dart';
import '../../../data/models/chapter_content_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/unlocked_chapter_model.dart';
import '../../../data/providers/service_providers.dart';
import '../../../features/auth/providers/auth_providers.dart';

/// Provider for fetching chapter metadata.
final chapterProvider =
    FutureProvider.family<ChapterModel?, ({String bookId, String chapterId})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(chapterRepositoryProvider);
      return repository.getChapter(params.bookId, params.chapterId);
    });

/// Provider for checking chapter access.
///
/// Combines chapter metadata, VIP status, and unlocked chapters to
/// determine if the current user can read the chapter.
final chapterAccessProvider =
    FutureProvider.family<
      ChapterAccessResult,
      ({String bookId, String chapterId, String userId})
    >((ref, params) async {
      final chapterRepository = ref.watch(chapterRepositoryProvider);
      final userRepository = ref.watch(userRepositoryProvider);
      final paymentRepository = ref.watch(paymentRepositoryProvider);
      final firebaseUser = ref.watch(firebaseUserProvider).value;
      if (firebaseUser?.uid != params.userId || params.userId.isEmpty) {
        return ChapterAccessResult.locked();
      }

      // Get chapter metadata
      final chapter = await chapterRepository.getChapter(
        params.bookId,
        params.chapterId,
      );
      if (chapter == null) {
        return ChapterAccessResult.locked();
      }

      // Get current user
      final currentUser = firebaseUser == null
          ? null
          : await userRepository.getUserById(firebaseUser.uid);
      if (currentUser == null) {
        return ChapterAccessResult.locked();
      }

      // Get unlocked chapters for this book
      var unlockedIds = await chapterRepository.getUserUnlockedChapters(
        currentUser.uid,
        params.bookId,
      );

      if (!unlockedIds.contains(params.chapterId)) {
        final approvedPayment = await paymentRepository
            .getApprovedChapterPayment(
              userId: currentUser.uid,
              chapterId: params.chapterId,
            );
        if (approvedPayment != null &&
            approvedPayment.bookId == params.bookId) {
          final unlockId = '${currentUser.uid}_${params.chapterId}';
          await chapterRepository.recordApprovedUnlock(
            UnlockedChapterModel(
              id: unlockId,
              userId: currentUser.uid,
              bookId: params.bookId,
              chapterId: params.chapterId,
              paymentId: approvedPayment.id,
              unlockedAt: approvedPayment.reviewedAt ?? DateTime.now(),
            ),
          );
          unlockedIds = [...unlockedIds, params.chapterId];
        }
      }

      return checkChapterAccess(
        chapter: chapter,
        isVipActive: currentUser.isVipActive,
        unlockedChapterIds: unlockedIds,
      );
    });

/// Provider for fetching chapter content.
///
/// Returns the text content or comic page URLs for a chapter.
/// Only call this after confirming access via [chapterAccessProvider].
final readerContentProvider =
    FutureProvider.family<
      ChapterContentModel?,
      ({String chapterId, String userId})
    >((ref, params) async {
      final firebaseUser = ref.watch(firebaseUserProvider).value;
      if (firebaseUser?.uid != params.userId || params.userId.isEmpty) {
        return null;
      }
      final repository = ref.watch(chapterRepositoryProvider);
      final content = await repository.getChapterContent(params.chapterId);

      if (content == null) return null;

      // Optimize comic page URLs for faster loading.
      if (content.isComic) {
        final cloudinary = ref.read(cloudinaryServiceProvider);
        return content.copyWith(
          pageUrls: content.pageUrls
              ?.map((url) => cloudinary.getOptimizedUrl(url, width: 1200))
              .toList(),
          contentBlocks: content.contentBlocks
              .map(
                (block) => block.type == 'image' && block.imageUrl != null
                    ? ChapterContentBlock.image(
                        cloudinary.getOptimizedUrl(
                          block.imageUrl!,
                          width: 1200,
                        ),
                      )
                    : block,
              )
              .toList(),
        );
      }

      return content;
    });

/// Provider for saving reading progress.
///
/// Saves the last read chapter to the user's library.
final saveProgressProvider =
    FutureProvider.family<
      void,
      ({String userId, String bookId, String chapterId})
    >((ref, params) async {
      final repository = ref.watch(libraryRepositoryProvider);
      await repository.saveProgress(
        userId: params.userId,
        bookId: params.bookId,
        chapterId: params.chapterId,
      );
    });

/// Provider for getting the last read chapter.
final lastChapterProvider =
    FutureProvider.family<String?, ({String userId, String bookId})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(libraryRepositoryProvider);
      return repository.getLastChapterId(params.userId, params.bookId);
    });
