import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/book_card.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../providers/library_providers.dart';

/// Main library screen with search, genre filter, and grid/list views.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load books on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryProvider.notifier).loadBooks();
    });

    // Infinite scroll listener.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(libraryProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    // Debounce search input.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _searchController.text == value) {
        ref.read(libraryProvider.notifier).search(value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    final genres = ref.watch(genreOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(state.isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: state.isGridView ? 'List view' : 'Grid view',
            onPressed: notifier.toggleViewMode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.search('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Genre filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: state.selectedGenre == null,
                    onSelected: (_) => notifier.filterByGenre(null),
                  ),
                ),
                for (final genre in genres)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(genre),
                      selected: state.selectedGenre == genre,
                      onSelected: (_) => notifier.filterByGenre(genre),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Book grid/list
          Expanded(
            child: _buildContent(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LibraryState state, LibraryNotifier notifier) {
    if (state.isLoading && state.books.isEmpty) {
      return const LoadingView(message: 'Loading books...');
    }

    if (state.error != null && state.books.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => notifier.loadBooks(),
      );
    }

    if (state.books.isEmpty) {
      return EmptyView(
        icon: Icons.library_books_outlined,
        message: state.searchTerm.isNotEmpty || state.selectedGenre != null
            ? 'No books found for your search.'
            : 'No books available yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadBooks(),
      child: state.isGridView
          ? _buildGrid(state, notifier)
          : _buildList(state, notifier),
    );
  }

  Widget _buildGrid(LibraryState state, LibraryNotifier notifier) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: state.books.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.books.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final book = state.books[index];
        return BookCard(
          title: book.title,
          author: book.author,
          coverUrl: book.coverUrl,
          rating: book.rating,
          onTap: () => context.push(RouteNames.getBookDetailsRoute(book.id)),
        );
      },
    );
  }

  Widget _buildList(LibraryState state, LibraryNotifier notifier) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: state.books.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.books.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final book = state.books[index];
        return BookListTile(
          title: book.title,
          author: book.author,
          coverUrl: book.coverUrl,
          rating: book.rating,
          onTap: () => context.push(RouteNames.getBookDetailsRoute(book.id)),
        );
      },
    );
  }
}
