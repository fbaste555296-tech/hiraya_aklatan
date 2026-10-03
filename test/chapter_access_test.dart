import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hiraya_aklatan/core/utils/chapter_access.dart';
import 'package:flutter_hiraya_aklatan/data/models/chapter_model.dart';

void main() {
  final now = DateTime.now();

  ChapterModel makeChapter({
    required String id,
    required int number,
    required DateTime releaseDate,
    required bool isEarlyAccess,
    double price = 0,
  }) =>
      ChapterModel(
        id: id,
        bookId: 'book-1',
        number: number,
        title: 'Chapter $number',
        releaseDate: releaseDate,
        isEarlyAccess: isEarlyAccess,
        price: price,
        type: 'text',
      );

  group('checkChapterAccess - Free chapters', () {
    test('released non-early-access chapter is free', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: false,
      );

      final result = checkChapterAccess(
        chapter: chapter,
        isVipActive: false,
        unlockedChapterIds: [],
      );

      expect(result.canAccess, isTrue);
      expect(result.reason, 'free');
    });

    test('unreleased non-early-access chapter is locked', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.add(const Duration(days: 1)),
        isEarlyAccess: false,
      );

      final result = checkChapterAccess(
        chapter: chapter,
        isVipActive: false,
        unlockedChapterIds: [],
      );

      expect(result.canAccess, isFalse);
      expect(result.reason, 'locked');
    });
  });

  group('checkChapterAccess - Early access chapters', () {
    test('early-access chapter without VIP or purchase is locked', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: true,
        price: 50,
      );

      final result = checkChapterAccess(
        chapter: chapter,
        isVipActive: false,
        unlockedChapterIds: [],
      );

      expect(result.canAccess, isFalse);
      expect(result.reason, 'early_access');
    });

    test('early-access chapter with active VIP is accessible', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: true,
        price: 50,
      );

      final result = checkChapterAccess(
        chapter: chapter,
        isVipActive: true,
        unlockedChapterIds: [],
      );

      expect(result.canAccess, isTrue);
      expect(result.reason, 'vip');
    });

    test('early-access chapter with purchase is accessible', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: true,
        price: 50,
      );

      final result = checkChapterAccess(
        chapter: chapter,
        isVipActive: false,
        unlockedChapterIds: ['c1'],
      );

      expect(result.canAccess, isTrue);
      expect(result.reason, 'purchased');
    });

    test('VIP does not unlock unreleased early-access chapters', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.add(const Duration(days: 1)),
        isEarlyAccess: true,
        price: 50,
      );

      final result = checkChapterAccess(
        chapter: chapter,
        isVipActive: true,
        unlockedChapterIds: [],
      );

      expect(result.canAccess, isFalse);
    });
  });

  group('checkChapterAccess - Priority order', () {
    test('free chapter takes priority over VIP', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: false,
      );

      final result = checkChapterAccess(
        chapter: chapter,
        isVipActive: true,
        unlockedChapterIds: ['c1'],
      );

      expect(result.canAccess, isTrue);
      expect(result.reason, 'free');
    });

    test('VIP takes priority over purchase', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: true,
        price: 50,
      );

      final result = checkChapterAccess(
        chapter: chapter,
        isVipActive: true,
        unlockedChapterIds: ['c1'],
      );

      expect(result.canAccess, isTrue);
      expect(result.reason, 'vip');
    });
  });

  group('ChapterAccessResult factories', () {
    test('free factory sets correct values', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now,
        isEarlyAccess: false,
      );

      final result = ChapterAccessResult.free(chapter);

      expect(result.canAccess, isTrue);
      expect(result.reason, 'free');
      expect(result.chapter, equals(chapter));
    });

    test('locked factory sets correct values', () {
      final result = ChapterAccessResult.locked();

      expect(result.canAccess, isFalse);
      expect(result.reason, 'locked');
      expect(result.chapter, isNull);
    });
  });
}
