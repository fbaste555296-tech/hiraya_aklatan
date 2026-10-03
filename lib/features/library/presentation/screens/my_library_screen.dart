import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/providers/service_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/library_providers.dart';

/// My Library screen showing books the user has started reading.
class MyLibraryScreen extends ConsumerWidget {
  const MyLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseUserProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: _MyLibraryContent(userId: user.uid),
    );
  }
}

/// Content for the My Library screen.
class _MyLibraryContent extends ConsumerWidget {
  const _MyLibraryContent({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(myLibraryProvider(userId));

    return libraryAsync.when(
      loading: () => const LoadingView(message: 'Loading your library...'),
      error: (error, _) => ErrorView(
        message: _friendlyError(error),
        onRetry: () => ref.invalidate(myLibraryProvider(userId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyView(
            icon: Icons.library_books_outlined,
            message: 'Your library is empty. Start reading to add books here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _LibraryItemCard(
              item: item,
              userId: userId,
              onTap: () => context.push(
                RouteNames.getBookDetailsRoute(item['bookId']),
              ),
            );
          },
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

/// Card displaying a book in the user's library.
class _LibraryItemCard extends ConsumerWidget {
  const _LibraryItemCard({
    required this.item,
    required this.userId,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final String userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookId = item['bookId'] as String;
    final title = item['title'] as String? ?? bookId;
    final author = item['author'] as String?;
    final coverUrl = item['coverUrl'] as String?;
    final lastChapterId = item['lastChapterId'] as String?;
    final updatedAt = item['updatedAt'] as DateTime?;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Book cover
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: coverUrl == null || coverUrl.isEmpty
                    ? Container(
                        width: 60,
                        height: 80,
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(
                          Icons.book,
                          color: AppColors.textDisabled,
                        ),
                      )
                    : Image.network(
                        coverUrl,
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(
                            Icons.book,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (author != null && author.isNotEmpty)
                      Text(
                        'by $author',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    if (lastChapterId != null)
                      Text(
                        'Last read: Chapter $lastChapterId',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    if (updatedAt != null)
                      Text(
                        'Updated ${Formatters.relativeTime(updatedAt)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill),
                    color: AppColors.primary,
                    tooltip: 'Continue Reading',
                    onPressed: lastChapterId != null
                        ? () => context.push(
                              RouteNames.getReaderRoute(bookId, lastChapterId),
                            )
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    color: AppColors.textSecondary,
                    tooltip: 'Remove from My Library',
                    onPressed: () async {
                      try {
                        await ref
                            .read(libraryRepositoryProvider)
                            .removeFromLibrary(
                              userId: userId,
                              bookId: bookId,
                            );
                        ref.invalidate(myLibraryProvider(userId));
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not remove book from My Library: $error',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
