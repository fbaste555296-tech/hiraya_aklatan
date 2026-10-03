import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/reader_providers.dart';
import 'locked_chapter_screen.dart';

/// Reader screen for reading text and comic chapters.
///
/// Handles both text chapters (scrollable, adjustable font size) and
/// comic chapters (InteractiveViewer with zoom). Saves reading progress.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
  });

  final String bookId;
  final String chapterId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  double _fontSize = AppConstants.defaultFontSize;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _increaseFontSize() {
    if (_fontSize < AppConstants.maxFontSize) {
      setState(() => _fontSize += AppConstants.fontSizeStep);
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > AppConstants.minFontSize) {
      setState(() => _fontSize -= AppConstants.fontSizeStep);
    }
  }

  void _saveProgress() {
    final user = ref.read(firebaseUserProvider).value;
    if (user == null) return;

    ref.read(
      saveProgressProvider((
        userId: user.uid,
        bookId: widget.bookId,
        chapterId: widget.chapterId,
      )).future,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseUserProvider).value;
    final userId = user?.uid ?? '';
    final accessParams = (
      bookId: widget.bookId,
      chapterId: widget.chapterId,
      userId: userId,
    );
    final accessAsync = ref.watch(chapterAccessProvider(accessParams));

    return accessAsync.when(
      skipLoadingOnReload: false,
      loading: () =>
          const Scaffold(body: LoadingView(message: 'Checking access...')),
      error: (error, _) => Scaffold(
        body: ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(chapterAccessProvider(accessParams)),
        ),
      ),
      data: (access) {
        if (!access.canAccess) {
          // Chapter is locked — show locked screen.
          return LockedChapterScreen(
            bookId: widget.bookId,
            chapter: access.chapter!,
          );
        }

        // Chapter is accessible — show reader.
        return _ReaderContent(
          bookId: widget.bookId,
          chapterId: widget.chapterId,
          userId: userId,
          fontSize: _fontSize,
          onIncreaseFontSize: _increaseFontSize,
          onDecreaseFontSize: _decreaseFontSize,
          onChapterChange: _saveProgress,
          scrollController: _scrollController,
        );
      },
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Exception:')) {
      return message.substring(message.indexOf('Exception:') + 11).trim();
    }
    return AppConstants.errorGeneric;
  }
}

/// Reader content for accessible chapters.
class _ReaderContent extends ConsumerWidget {
  const _ReaderContent({
    required this.bookId,
    required this.chapterId,
    required this.userId,
    required this.fontSize,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    required this.onChapterChange,
    required this.scrollController,
  });

  final String bookId;
  final String chapterId;
  final String userId;
  final double fontSize;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;
  final VoidCallback onChapterChange;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentParams = (chapterId: chapterId, userId: userId);
    final contentAsync = ref.watch(readerContentProvider(contentParams));
    final chapterAsync = ref.watch(
      chapterProvider((bookId: bookId, chapterId: chapterId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(chapterAsync.value?.title ?? 'Chapter'),
        actions: [
          // Font size controls (only for text chapters)
          if (contentAsync.value?.isText == true) ...[
            IconButton(
              icon: const Icon(Icons.text_decrease),
              tooltip: 'Decrease font size',
              onPressed: onDecreaseFontSize,
            ),
            IconButton(
              icon: const Icon(Icons.text_increase),
              tooltip: 'Increase font size',
              onPressed: onIncreaseFontSize,
            ),
          ],
        ],
      ),
      body: contentAsync.when(
        skipLoadingOnReload: false,
        loading: () => const LoadingView(message: 'Loading chapter...'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(readerContentProvider(contentParams)),
        ),
        data: (content) {
          if (content == null) {
            return const ErrorView(message: 'Chapter content not found.');
          }

          // Save progress when content loads.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChapterChange();
          });

          if (content.isText) {
            return _TextReader(
              content: content.textContent!,
              fontSize: fontSize,
              scrollController: scrollController,
            );
          } else if (content.isComic) {
            return _ComicReader(pageUrls: content.pageUrls!);
          }

          return const ErrorView(message: 'Unsupported chapter type.');
        },
      ),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Exception:')) {
      return message.substring(message.indexOf('Exception:') + 11).trim();
    }
    return AppConstants.errorGeneric;
  }
}

/// Text chapter reader with adjustable font size.
class _TextReader extends StatelessWidget {
  const _TextReader({
    required this.content,
    required this.fontSize,
    required this.scrollController,
  });

  final String content;
  final double fontSize;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        content,
        style: AppTextStyles.readingBody.copyWith(fontSize: fontSize),
      ),
    );
  }
}

/// Comic chapter reader with zoom and page navigation.
class _ComicReader extends StatefulWidget {
  const _ComicReader({required this.pageUrls});

  final List<String> pageUrls;

  @override
  State<_ComicReader> createState() => _ComicReaderState();
}

class _ComicReaderState extends State<_ComicReader> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page indicator
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            'Page ${_currentPage + 1} of ${widget.pageUrls.length}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),

        // Comic pages with zoom
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.pageUrls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: widget.pageUrls[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Center(child: Icon(Icons.error_outline, size: 48)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
