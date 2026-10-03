import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/models/chapter_model.dart';
import '../../../../data/providers/service_providers.dart';
import '../../providers/admin_providers.dart';

/// Admin screen for managing chapters of a book.
class AdminChaptersScreen extends ConsumerWidget {
  const AdminChaptersScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(adminChaptersProvider(bookId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Chapters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Chapter',
            onPressed: () => context.push('/admin/books/$bookId/chapters/new'),
          ),
        ],
      ),
      body: chaptersAsync.when(
        loading: () => const LoadingView(message: 'Loading chapters...'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(adminChaptersProvider(bookId)),
        ),
        data: (chapters) {
          if (chapters.isEmpty) {
            return const EmptyView(
              icon: Icons.list_alt,
              message: 'No chapters yet. Add your first chapter!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return _ChapterListCard(chapter: chapter);
            },
          );
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

/// Card displaying a chapter in the admin list.
class _ChapterListCard extends ConsumerWidget {
  const _ChapterListCard({required this.chapter});

  final ChapterModel chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: chapter.isEarlyAccess
              ? AppColors.statusPending.withValues(alpha: 0.1)
              : AppColors.statusApproved.withValues(alpha: 0.1),
          child: Text(
            '${chapter.number}',
            style: TextStyle(
              color: chapter.isEarlyAccess
                  ? AppColors.statusPending
                  : AppColors.statusApproved,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(chapter.title),
        subtitle: Text(
          '${chapter.isEarlyAccess ? "Early Access" : "Free"} - ${Formatters.currency(chapter.price)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () => context.push(
                '/admin/books/${chapter.bookId}/chapters/${chapter.id}/edit',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chapter'),
        content: Text('Are you sure you want to delete "${chapter.title}"?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              try {
                final repository = ref.read(chapterRepositoryProvider);
                await repository.deleteChapter(chapter.bookId, chapter.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chapter deleted.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to delete: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
