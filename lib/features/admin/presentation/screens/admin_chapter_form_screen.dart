import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/loading_view.dart';
import '../../../reader/providers/reader_providers.dart';
import '../widgets/chapter_form_widget.dart';

/// Admin screen for creating a new chapter.
class AdminNewChapterScreen extends ConsumerWidget {
  const AdminNewChapterScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Chapter')),
      body: ChapterFormWidget(bookId: bookId),
    );
  }
}

/// Admin screen for editing an existing chapter.
class AdminEditChapterScreen extends ConsumerWidget {
  const AdminEditChapterScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
  });

  final String bookId;
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync =
        ref.watch(chapterProvider((bookId: bookId, chapterId: chapterId)));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Chapter')),
      body: chapterAsync.when(
        loading: () => const LoadingView(message: 'Loading chapter...'),
        error: (error, _) =>
            Center(child: Text('Error: ${error.toString()}')),
        data: (chapter) {
          if (chapter == null) {
            return const Center(child: Text('Chapter not found.'));
          }
          return ChapterFormWidget(
            bookId: bookId,
            existingChapter: chapter,
          );
        },
      ),
    );
  }
}
