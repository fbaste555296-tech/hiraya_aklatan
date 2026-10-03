import 'package:flutter_test/flutter_test.dart';
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

  group('ChapterModel.isReleased', () {
    test('returns true for past release dates', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: false,
      );
      expect(chapter.isReleased, isTrue);
    });

    test('returns true for current release date', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now,
        isEarlyAccess: false,
      );
      expect(chapter.isReleased, isTrue);
    });

    test('returns false for future release dates', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.add(const Duration(days: 1)),
        isEarlyAccess: false,
      );
      expect(chapter.isReleased, isFalse);
    });
  });

  group('ChapterModel.isFree', () {
    test('returns true for released non-early-access chapters', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: false,
      );
      expect(chapter.isFree, isTrue);
    });

    test('returns false for early-access chapters even if released', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: true,
      );
      expect(chapter.isFree, isFalse);
    });

    test('returns false for unreleased chapters', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.add(const Duration(days: 1)),
        isEarlyAccess: false,
      );
      expect(chapter.isFree, isFalse);
    });
  });

  group('ChapterModel.isLocked', () {
    test('returns false for free chapters', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: false,
      );
      expect(chapter.isLocked, isFalse);
    });

    test('returns true for early-access chapters', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.subtract(const Duration(days: 1)),
        isEarlyAccess: true,
      );
      expect(chapter.isLocked, isTrue);
    });

    test('returns true for unreleased chapters', () {
      final chapter = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now.add(const Duration(days: 1)),
        isEarlyAccess: false,
      );
      expect(chapter.isLocked, isTrue);
    });
  });

  group('ChapterModel.copyWith', () {
    test('creates a copy with updated fields', () {
      final original = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now,
        isEarlyAccess: false,
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isEarlyAccess: true,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.isEarlyAccess, isTrue);
      expect(updated.id, original.id);
      expect(updated.number, original.number);
    });

    test('keeps original values when no updates provided', () {
      final original = makeChapter(
        id: 'c1',
        number: 1,
        releaseDate: now,
        isEarlyAccess: false,
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.isEarlyAccess, original.isEarlyAccess);
    });
  });
}
