import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/service_providers.dart';
import '../../features/admin/presentation/screens/admin_book_form_screen.dart';
import '../../features/admin/presentation/screens/admin_books_screen.dart';
import '../../features/admin/presentation/screens/admin_chapter_form_screen.dart';
import '../../features/admin/presentation/screens/admin_chapters_screen.dart';
import '../../features/admin/presentation/screens/admin_payments_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/book_details/presentation/screens/book_details_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/my_library_screen.dart';
import '../../features/payments/presentation/screens/payment_history_screen.dart';
import '../../features/payments/presentation/screens/payment_instructions_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reader/presentation/screens/reader_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/vip/presentation/screens/vip_screen.dart';
import '../../core/theme/app_colors.dart';
import 'auth_guard.dart';
import 'main_shell.dart';
import 'route_names.dart';

/// Provider for the auth guard.
final authGuardProvider = Provider<AuthGuard>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthGuard(userRepository: userRepository);
});

/// Application router with auth and role-based redirects.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authGuard = ref.watch(authGuardProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    // Re-evaluate redirects whenever the auth state changes.
    refreshListenable: GoRouterRefreshNotifier(ref),
    redirect: (context, state) {
      final isAuthenticated = ref.read(firebaseUserProvider).value != null;
      final isOnAuthPage =
          state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.register ||
          state.matchedLocation == RouteNames.forgotPassword;

      if (!isAuthenticated && !isOnAuthPage) {
        return RouteNames.login;
      }
      if (isAuthenticated && isOnAuthPage) {
        return RouteNames.library;
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app shell with role-aware bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.library,
            name: 'library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: RouteNames.myLibrary,
            name: 'my-library',
            builder: (context, state) => const MyLibraryScreen(),
          ),
          GoRoute(
            path: RouteNames.vip,
            name: 'vip',
            builder: (context, state) => const VipScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: RouteNames.admin,
        name: 'admin',
        redirect: (context, state) => authGuard
            .adminRedirect(context, state)
            .then((destination) => destination ?? RouteNames.adminPayments),
      ),

      // Book details (outside shell for full screen)
      GoRoute(
        path: RouteNames.bookDetails,
        name: 'book-details',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return BookDetailsScreen(bookId: bookId);
        },
      ),

      // Reader (outside shell for full screen)
      GoRoute(
        path: RouteNames.reader,
        name: 'reader',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final chapterId = state.pathParameters['chapterId']!;
          return ReaderScreen(bookId: bookId, chapterId: chapterId);
        },
      ),

      // Payment routes (outside shell)
      GoRoute(
        path: RouteNames.paymentInstructions,
        name: 'payment-instructions',
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          final targetId = state.pathParameters['targetId']!;
          return PaymentInstructionsScreen(
            type: type,
            targetId: targetId,
            planType: type == 'vip' ? targetId : null,
            chapterBookId: state.uri.queryParameters['bookId'],
          );
        },
      ),
      GoRoute(
        path: RouteNames.paymentHistory,
        name: 'payment-history',
        builder: (context, state) => const PaymentHistoryScreen(),
      ),

      // Admin routes (outside shell for full screen)
      GoRoute(
        path: RouteNames.adminBooks,
        name: 'admin-books',
        builder: (context, state) => const AdminBooksScreen(),
        redirect: (context, state) => authGuard.adminRedirect(context, state),
      ),
      GoRoute(
        path: '/admin/books/new',
        name: 'admin-books-new',
        builder: (context, state) => const AdminNewBookScreen(),
        redirect: (context, state) => authGuard.adminRedirect(context, state),
      ),
      GoRoute(
        path: '/admin/books/:bookId/edit',
        name: 'admin-books-edit',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return AdminEditBookScreen(bookId: bookId);
        },
        redirect: (context, state) => authGuard.adminRedirect(context, state),
      ),
      GoRoute(
        path: RouteNames.adminChapters,
        name: 'admin-chapters',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return AdminChaptersScreen(bookId: bookId);
        },
        redirect: (context, state) => authGuard.adminRedirect(context, state),
      ),
      GoRoute(
        path: '/admin/books/:bookId/chapters/new',
        name: 'admin-chapters-new',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return AdminNewChapterScreen(bookId: bookId);
        },
        redirect: (context, state) => authGuard.adminRedirect(context, state),
      ),
      GoRoute(
        path: '/admin/books/:bookId/chapters/:chapterId/edit',
        name: 'admin-chapters-edit',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final chapterId = state.pathParameters['chapterId']!;
          return AdminEditChapterScreen(bookId: bookId, chapterId: chapterId);
        },
        redirect: (context, state) => authGuard.adminRedirect(context, state),
      ),
      GoRoute(
        path: RouteNames.adminPayments,
        name: 'admin-payments',
        builder: (context, state) => const AdminPaymentsScreen(),
        redirect: (context, state) => authGuard.adminRedirect(context, state),
      ),
      GoRoute(
        path: RouteNames.adminUsers,
        name: 'admin-users',
        builder: (context, state) => const AdminUsersScreen(),
        redirect: (context, state) => authGuard.adminRedirect(context, state),
      ),
      GoRoute(
        path: RouteNames.adminSettings,
        name: 'admin-settings',
        builder: (context, state) => const AdminSettingsScreen(),
        redirect: (context, state) => authGuard.adminRedirect(context, state),
      ),
    ],
    errorBuilder: (context, state) => const PlaceholderScreen(
      title: 'Page Not Found',
      message: 'The requested page was not found.',
    ),
  );
});

/// Notifies the router to re-evaluate redirects when auth state changes.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(firebaseUserProvider, (_, _) => notifyListeners());
  }
}

/// Temporary placeholder screen for routes implemented in later phases.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
