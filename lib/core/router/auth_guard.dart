import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../config/app_constants.dart';
import 'route_names.dart';

/// Route guard protecting pages based on authentication and role.
///
/// The guard is synchronous for auth checks (the current Firebase user is
/// available immediately after startup) and performs a single Firestore read
/// for admin checks.
class AuthGuard {
  AuthGuard({required this._userRepository});

  final UserRepository _userRepository;

  /// Redirects unauthenticated users to the login page.
  String? authRedirect(BuildContext context, GoRouterState state) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return RouteNames.login;
    }

    return null;
  }

  /// Redirects already-authenticated users away from auth pages.
  String? guestRedirect(BuildContext context, GoRouterState state) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return RouteNames.library;
    }

    return null;
  }

  /// Admin-only route guard: non-admins are sent back to the library.
  Future<String?> adminRedirect(BuildContext context, GoRouterState state) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return RouteNames.login;
    }

    try {
      final UserModel? userModel = await _userRepository.getUserById(user.uid);

      if (userModel == null || userModel.role != AppConstants.roleAdmin) {
        return RouteNames.library;
      }

      return null;
    } catch (_) {
      // Fail closed: on any error, keep the user out of admin routes.
      return RouteNames.library;
    }
  }
}
