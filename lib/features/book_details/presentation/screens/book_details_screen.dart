import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/chapter_list_tile.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../data/models/book_model.dart';
import '../../../../data/providers/service_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../library/providers/library_providers.dart';
import '../../providers/book_details_providers.dart';

/// Book details screen showing book info and chapter list.
class BookDetailsScreen extends ConsumerWidget {
  const BookDetailsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailsProvider(bookId));

    return Scaffold(
      body: bookAsync.when(
        loading: () => const LoadingView(message: 'Loading book...'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(bookDetailsProvider(bookId)),
        ),
        data: (book) {
          if (book == null) {
            return const EmptyView(
              icon: Icons.book_outlined,
              message: 'Book not found.',
            );
          }
          return _BookDetailsContent(book: book);
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

/// Scrollable content for the book details screen.
class _BookDetailsContent extends ConsumerWidget {
  const _BookDetailsContent({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersProvider(book.id));

    return CustomScrollView(
      slivers: [
        // Collapsible app bar with cover image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _CoverImage(coverUrl: book.coverUrl),
          ),
        ),

        // Book info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Author
                Text(
                  'by ${book.author}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),

                // Rating and status
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      book.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '(${book.ratingCount} ${book.ratingCount == 1 ? 'rating' : 'ratings'})',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    StatusChip(status: book.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _BookRatingControl(bookId: book.id),
                const SizedBox(height: AppSpacing.md),
                const SizedBox(height: AppSpacing.md),

                // Genres
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final genre in book.genres)
                      Chip(
                        label: Text(genre),
                        backgroundColor: AppColors.surfaceVariant,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Summary
                Text('Summary', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  book.summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                _AddToLibraryButton(book: book),
                const SizedBox(height: AppSpacing.xl),

                // Chapters header
                Row(
                  children: [
                    Text(
                      'Chapters',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '(${chaptersAsync.value?.length ?? '...'})',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),

        // Chapter list
        chaptersAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ErrorView(
                message: _friendlyError(error),
                onRetry: () => ref.invalidate(chaptersProvider(book.id)),
              ),
            ),
          ),
          data: (chapters) {
            if (chapters.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: EmptyView(
                    icon: Icons.list_alt,
                    message: 'No chapters available yet.',
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final chapter = chapters[index];
                return ChapterListTile(
                  chapter: chapter,
                  onTap: () => context.push(
                    RouteNames.getReaderRoute(book.id, chapter.id),
                  ),
                );
              }, childCount: chapters.length),
            );
          },
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
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

class _BookRatingControl extends ConsumerStatefulWidget {
  const _BookRatingControl({required this.bookId});

  final String bookId;

  @override
  ConsumerState<_BookRatingControl> createState() => _BookRatingControlState();
}

class _BookRatingControlState extends ConsumerState<_BookRatingControl> {
  bool _isSaving = false;

  Future<void> _rate(String userId, int rating) async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(bookRepositoryProvider)
          .rateBook(bookId: widget.bookId, userId: userId, rating: rating);
      ref.invalidate(bookDetailsProvider(widget.bookId));
      ref.invalidate(
        userBookRatingProvider((bookId: widget.bookId, userId: userId)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your rating has been saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save rating: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseUserProvider).value;
    if (user == null) {
      return const Text('Sign in to rate this book.');
    }

    final ratingAsync = ref.watch(
      userBookRatingProvider((bookId: widget.bookId, userId: user.uid)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rate this book', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        ratingAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => TextButton(
            onPressed: () => ref.invalidate(
              userBookRatingProvider((bookId: widget.bookId, userId: user.uid)),
            ),
            child: const Text('Could not load your rating. Tap to retry.'),
          ),
          data: (currentRating) => Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  tooltip: 'Rate $star out of 5',
                  onPressed: _isSaving ? null : () => _rate(user.uid, star),
                  icon: Icon(
                    star <= (currentRating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.accent,
                  ),
                ),
              if (currentRating != null) Text('Your rating: $currentRating/5'),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddToLibraryButton extends ConsumerStatefulWidget {
  const _AddToLibraryButton({required this.book});

  final BookModel book;

  @override
  ConsumerState<_AddToLibraryButton> createState() =>
      _AddToLibraryButtonState();
}

class _AddToLibraryButtonState extends ConsumerState<_AddToLibraryButton> {
  bool _isSaving = false;

  Future<void> _toggleLibrary(String userId, bool isInLibrary) async {
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(libraryRepositoryProvider);
      if (isInLibrary) {
        await repository.removeFromLibrary(
          userId: userId,
          bookId: widget.book.id,
        );
      } else {
        await repository.addBook(
          userId: userId,
          bookId: widget.book.id,
          title: widget.book.title,
          author: widget.book.author,
          coverUrl: widget.book.coverUrl,
        );
      }

      ref.invalidate(
        bookInLibraryProvider((userId: userId, bookId: widget.book.id)),
      );
      ref.invalidate(myLibraryProvider(userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isInLibrary ? 'Removed from My Library.' : 'Added to My Library.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update My Library: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final membership = ref.watch(
      bookInLibraryProvider((userId: user.uid, bookId: widget.book.id)),
    );

    return membership.when(
      loading: () => OutlinedButton.icon(
        onPressed: null,
        icon: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text('Checking My Library'),
      ),
      error: (error, _) => OutlinedButton.icon(
        onPressed: () => ref.invalidate(
          bookInLibraryProvider((userId: user.uid, bookId: widget.book.id)),
        ),
        icon: const Icon(Icons.refresh),
        label: const Text('Retry My Library'),
      ),
      data: (isInLibrary) => OutlinedButton.icon(
        onPressed: _isSaving
            ? null
            : () => _toggleLibrary(user.uid, isInLibrary),
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isInLibrary ? Icons.bookmark : Icons.bookmark_add_outlined),
        label: Text(
          isInLibrary ? 'Remove from My Library' : 'Add to My Library',
        ),
      ),
    );
  }
}

/// Book cover image with loading and error states.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverUrl});

  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.surfaceVariant,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.book, size: 64, color: AppColors.textDisabled),
        ),
      ),
    );
  }
}
