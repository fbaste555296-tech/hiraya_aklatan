import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hiraya_aklatan/data/models/chapter_content_model.dart';

void main() {
  group('ChapterContentModel', () {
    test('round-trips ordered text and image sections', () {
      const content = ChapterContentModel(
        chapterId: 'chapter-1',
        bookId: 'book-1',
        contentBlocks: [
          ChapterContentBlock.text('First section'),
          ChapterContentBlock.image('https://example.com/image.jpg'),
          ChapterContentBlock.text('Second section'),
        ],
      );

      final restored = ChapterContentModel.fromMap(
        content.toMap(),
        content.chapterId,
      );

      expect(
        restored.contentBlocks.map((block) => block.type),
        ['text', 'image', 'text'],
      );
      expect(restored.contentBlocks.first.text, 'First section');
      expect(
        restored.contentBlocks[1].imageUrl,
        'https://example.com/image.jpg',
      );
      expect(restored.contentBlocks.last.text, 'Second section');
      expect(restored.isText, isTrue);
      expect(restored.isComic, isTrue);
    });

    test('maps legacy text and comic content to reading order', () {
      const content = ChapterContentModel(
        chapterId: 'chapter-1',
        bookId: 'book-1',
        textContent: 'Legacy text',
        pageUrls: ['https://example.com/page.jpg'],
      );

      expect(
        content.orderedContent.map((block) => block.type),
        ['text', 'image'],
      );
      expect(content.orderedContent.first.text, 'Legacy text');
      expect(
        content.orderedContent.last.imageUrl,
        'https://example.com/page.jpg',
      );
    });
  });
}
