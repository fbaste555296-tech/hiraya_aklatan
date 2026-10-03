/// Application route names
class RouteNames {
  RouteNames._();

  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main app routes
  static const String library = '/library';
  static const String myLibrary = '/my-library';
  static const String vip = '/vip';
  static const String profile = '/profile';

  // Book routes
  static const String bookDetails = '/book/:bookId';
  static const String reader = '/book/:bookId/chapter/:chapterId';

  // Payment routes
  static const String payment = '/payment';
  static const String paymentHistory = '/payment-history';
  static const String paymentInstructions = '/payment/:type/:targetId';

  // Admin routes
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminBooks = '/admin/books';
  static const String adminChapters = '/admin/books/:bookId/chapters';
  static const String adminPayments = '/admin/payments';
  static const String adminUsers = '/admin/users';
  static const String adminSettings = '/admin/settings';

  // Utility routes
  static const String splash = '/splash';
  static const String notFound = '/not-found';

  /// Gets book details route with bookId
  static String getBookDetailsRoute(String bookId) => '/book/$bookId';

  /// Gets reader route with bookId and chapterId
  static String getReaderRoute(String bookId, String chapterId) =>
      '/book/$bookId/chapter/$chapterId';

  /// Gets payment instructions route
  static String getPaymentInstructionsRoute(
    String type,
    String targetId, {
    String? bookId,
  }) {
    final path = '/payment/$type/$targetId';
    return bookId == null
        ? path
        : Uri(path: path, queryParameters: {'bookId': bookId}).toString();
  }

  /// Gets admin chapters route with bookId
  static String getAdminChaptersRoute(String bookId) => '/admin/books/$bookId/chapters';
}