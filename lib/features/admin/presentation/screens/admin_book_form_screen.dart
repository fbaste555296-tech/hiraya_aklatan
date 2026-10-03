import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/loading_view.dart';
import '../../../book_details/providers/book_details_providers.dart';
import '../widgets/book_form_widget.dart';

/// Admin screen for creating a new book.
class AdminNewBookScreen extends ConsumerWidget {
  const AdminNewBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Book')),
      body: const BookFormWidget(),
    );
  }
}

/// Admin screen for editing an existing book.
class AdminEditBookScreen extends ConsumerWidget {
  const AdminEditBookScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailsProvider(bookId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Book')),
      body: bookAsync.when(
        loading: () => const LoadingView(message: 'Loading book...'),
        error: (error, _) => Center(child: Text('Error: ${error.toString()}')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('Book not found.'));
          }
          return BookFormWidget(existingBook: book);
        },
      ),
    );
  }
}
