import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../data/models/book_model.dart';
import '../../../../data/providers/service_providers.dart';
import '../../providers/admin_providers.dart';

/// Admin screen for managing books.
class AdminBooksScreen extends ConsumerWidget {
  const AdminBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(adminBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Book',
            onPressed: () => context.push('/admin/books/new'),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const LoadingView(message: 'Loading books...'),
        error: (error, _) => ErrorView(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(adminBooksProvider),
        ),
        data: (books) {
          if (books.isEmpty) {
            return const EmptyView(
              icon: Icons.library_books,
              message: 'No books yet. Add your first book!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return _BookListCard(book: book);
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

/// Card displaying a book in the admin list.
class _BookListCard extends ConsumerWidget {
  const _BookListCard({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Image.network(
            book.coverUrl,
            width: 50,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 50,
              height: 70,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.book, size: 24),
            ),
          ),
        ),
        title: Text(book.title),
        subtitle: Text(book.author),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () => context.push('/admin/books/${book.id}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        onTap: () => context.push(RouteNames.getAdminChaptersRoute(book.id)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              try {
                final repository = ref.read(bookRepositoryProvider);
                await repository.deleteBook(book.id);
                ref.invalidate(adminBooksProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book deleted.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: ${e.toString()}')),
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
