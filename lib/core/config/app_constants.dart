/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Hiraya Aklatan';
  static const String appTagline = 'Digital Library';

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String booksCollection = 'books';
  static const String chaptersCollection = 'chapters';
  static const String chapterContentsCollection = 'chapterContents';
  static const String unlockedChaptersCollection = 'unlockedChapters';
  static const String paymentsCollection = 'payments';
  static const String librariesCollection = 'libraries';
  static const String settingsCollection = 'settings';

  // Settings document
  static const String appSettingsDoc = 'app';
  static const double defaultVipMonthlyPrice = 99;
  static const double defaultVipYearlyPrice = 899;

  // User roles
  static const String roleReader = 'reader';
  static const String roleAdmin = 'admin';

  // Book status
  static const String bookStatusOngoing = 'ongoing';
  static const String bookStatusCompleted = 'completed';
  static const String bookStatusHiatus = 'hiatus';

  // Chapter types
  static const String chapterTypeText = 'text';
  static const String chapterTypeComic = 'comic';

  // Payment types
  static const String paymentTypeChapter = 'chapter';
  static const String paymentTypeVip = 'vip';

  // Payment status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusApproved = 'approved';
  static const String paymentStatusRejected = 'rejected';

  // VIP plan types
  static const String vipPlanMonthly = 'monthly';
  static const String vipPlanYearly = 'yearly';

  // VIP plan durations (in days)
  static const int vipMonthlyDays = 30;
  static const int vipYearlyDays = 365;

  // Cloudinary folders
  static const String cloudinaryCoversFolder = 'covers';
  static const String cloudinaryComicPagesFolder = 'comic_pages';
  static const String cloudinaryProofsFolder = 'proofs';
  static const String cloudinaryAvatarsFolder = 'avatars';

  // Image constraints
  static const int maxImageSizeMB = 5;
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  // Pagination
  static const int booksPerPage = 20;
  static const int chaptersPerPage = 50;

  // Genre options
  static const List<String> genres = [
    'Fantasy',
    'Romance',
    'Mystery',
    'Thriller',
    'Science Fiction',
    'Horror',
    'Comedy',
    'Drama',
    'Action',
    'Adventure',
    'Historical',
    'Contemporary',
    'Young Adult',
    'Slice of Life',
  ];

  // Reading settings defaults
  static const double defaultFontSize = 18.0;
  static const double minFontSize = 14.0;
  static const double maxFontSize = 28.0;
  static const double fontSizeStep = 2.0;

  // Error messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorPermission = 'You do not have permission to perform this action.';
  static const String errorNotFound = 'The requested resource was not found.';

  // Success messages
  static const String successLogin = 'Logged in successfully';
  static const String successRegister = 'Account created successfully';
  static const String successLogout = 'Logged out successfully';
  static const String successPaymentSubmitted = 'Payment submitted for review';
  static const String successPaymentApproved = 'Payment approved successfully';
  static const String successPaymentRejected = 'Payment rejected';

  // Validation limits
  static const int minPasswordLength = 6;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxTitleLength = 200;
  static const int maxSummaryLength = 1000;
  static const int minChapterNumber = 1;

  // E-wallet providers
  static const List<String> ewalletProviders = ['GCash', 'Maya'];
}
