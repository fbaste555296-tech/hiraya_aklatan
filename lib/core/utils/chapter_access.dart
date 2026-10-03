import '../../data/models/chapter_model.dart';

/// Result of a chapter access check.
class ChapterAccessResult {
  const ChapterAccessResult({
    required this.canAccess,
    required this.reason,
    this.chapter,
  });

  final bool canAccess;
  final String reason;
  final ChapterModel? chapter;

  /// Chapter is free to read.
  factory ChapterAccessResult.free(ChapterModel chapter) =>
      ChapterAccessResult(canAccess: true, reason: 'free', chapter: chapter);

  /// Chapter is accessible via VIP subscription.
  factory ChapterAccessResult.vip(ChapterModel chapter) =>
      ChapterAccessResult(canAccess: true, reason: 'vip', chapter: chapter);

  /// Chapter is accessible via purchase.
  factory ChapterAccessResult.purchased(ChapterModel chapter) =>
      ChapterAccessResult(canAccess: true, reason: 'purchased', chapter: chapter);

  /// Chapter is locked (not yet released).
  factory ChapterAccessResult.locked([ChapterModel? chapter]) =>
      ChapterAccessResult(canAccess: false, reason: 'locked', chapter: chapter);

  /// Chapter is locked (early access, not purchased).
  factory ChapterAccessResult.earlyAccess(ChapterModel chapter) =>
      ChapterAccessResult(
          canAccess: false, reason: 'early_access', chapter: chapter);
}

/// Determines if a user can access a chapter.
///
/// Access rules:
/// 1. Free chapters (released + not early access) → always accessible
/// 2. VIP users → can access all released chapters
/// 3. Purchased chapters → accessible via unlockedChapters record
/// 4. Otherwise → locked
ChapterAccessResult checkChapterAccess({
  required ChapterModel chapter,
  required bool isVipActive,
  required List<String> unlockedChapterIds,
}) {
  // Rule 1: Free chapters are always accessible
  if (chapter.isFree) {
    return ChapterAccessResult.free(chapter);
  }

  // Rule 2: VIP users can access all released chapters
  if (isVipActive && chapter.isReleased) {
    return ChapterAccessResult.vip(chapter);
  }

  // Rule 3: Check if user purchased this specific chapter
  if (unlockedChapterIds.contains(chapter.id)) {
    return ChapterAccessResult.purchased(chapter);
  }

  // Rule 4: Chapter is locked
  if (chapter.isEarlyAccess) {
    return ChapterAccessResult.earlyAccess(chapter);
  }

  return ChapterAccessResult.locked(chapter);
}
