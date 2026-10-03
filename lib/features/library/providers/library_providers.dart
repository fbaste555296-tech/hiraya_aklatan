import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../data/models/book_model.dart';
import '../../../data/providers/service_providers.dart';

/// State for the library screen.
class LibraryState {
  const LibraryState({
    this.books = const [],
    this.searchTerm = '',
    this.selectedGenre,
    this.isGridView = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
  });

  final List<BookModel> books;
  final String searchTerm;
  final String? selectedGenre;
  final bool isGridView;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;

  LibraryState copyWith({
    List<BookModel>? books,
    String? searchTerm,
    String? selectedGenre,
    bool? isGridView,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    bool clearGenre = false,
    bool clearError = false,
  }) {
    return LibraryState(
      books: books ?? this.books,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedGenre: clearGenre ? null : (selectedGenre ?? this.selectedGenre),
      isGridView: isGridView ?? this.isGridView,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Notifier managing the library screen state: search, genre filter,
/// view mode, and pagination.
class LibraryNotifier extends Notifier<LibraryState> {
  DocumentSnapshot? _lastDocument;

  @override
  LibraryState build() => const LibraryState();

  /// Loads the first page of books. Called on init and pull-to-refresh.
  Future<void> loadBooks() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);
    _lastDocument = null;

    try {
      final repository = ref.read(bookRepositoryProvider);
      final result = await repository.getBooks(
        genre: state.selectedGenre,
        searchTerm: state.searchTerm,
      );

      _lastDocument = result.lastDocument;

      state = state.copyWith(
        books: _optimizeCoverUrls(result.books),
        isLoading: false,
        hasMore: result.books.length >= AppConstants.booksPerPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  /// Loads the next page of books (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || _lastDocument == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = ref.read(bookRepositoryProvider);
      final result = await repository.getBooks(
        startAfter: _lastDocument,
        genre: state.selectedGenre,
        searchTerm: state.searchTerm,
      );

      _lastDocument = result.lastDocument;

      final allBooks = [...state.books, ..._optimizeCoverUrls(result.books)];

      state = state.copyWith(
        books: allBooks,
        isLoadingMore: false,
        hasMore: result.books.length >= AppConstants.booksPerPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Updates the search term and reloads books.
  Future<void> search(String term) async {
    state = state.copyWith(searchTerm: term);
    await loadBooks();
  }

  /// Updates the selected genre filter and reloads books.
  Future<void> filterByGenre(String? genre) async {
    state = state.copyWith(selectedGenre: genre, clearGenre: genre == null);
    await loadBooks();
  }

  /// Toggles between grid and list view modes.
  void toggleViewMode() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  /// Optimizes book cover URLs using Cloudinary transformations.
  List<BookModel> _optimizeCoverUrls(List<BookModel> books) {
    final cloudinary = ref.read(cloudinaryServiceProvider);
    return books
        .map((book) => book.copyWith(
              coverUrl: cloudinary.getCoverUrl(book.coverUrl),
            ))
        .toList();
  }

  /// Converts errors to user-friendly messages.
  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Exception:')) {
      return message.substring(message.indexOf('Exception:') + 11).trim();
    }
    return AppConstants.errorGeneric;
  }
}

/// Library state notifier provider.
final libraryProvider =
    NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);

/// Available genre options for the filter.
final genreOptionsProvider = Provider<List<String>>((ref) {
  return AppConstants.genres;
});

/// Provider for the user's library (books with reading progress).
final myLibraryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.getUserLibrary(userId);
});

/// Provider for checking whether a book is in the user's library.
final bookInLibraryProvider = FutureProvider.family<bool,
    ({String userId, String bookId})>((ref, params) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.containsBook(params.userId, params.bookId);
});
