// lib/features/auth/providers/auth_providers.dart
export '../viewmodels/current_user_viewmodel.dart'
    show
        currentUserViewModelProvider,
        currentUserProvider,
        isAdminProvider,
        isVipProvider,
        isAuthenticatedProvider,
        firebaseUserProvider;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/service_providers.dart';
import '../../../data/repositories/auth_repository.dart';

/// Auth repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AuthRepository(firestoreService: firestoreService);
});

/// Stream of the raw Firebase auth user (null when signed out).
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Authentication state notifier backing the login/register/forgot-password
/// forms. Exposes [AsyncValue] so forms can render loading and error states.
class AuthNotifier extends Notifier<AsyncValue<void>> {
  late final AuthRepository _authRepository = ref.read(authRepositoryProvider);

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Signs in with email and password.
  /// Returns true on success so callers can navigate.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Signs in with Google.
  /// Returns true on success so callers can navigate.
  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.signInWithGoogle();
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Registers a new reader account.
  /// Returns true on success so callers can navigate.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Sends a password reset email. Returns true on success.
  Future<bool> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

/// Auth state notifier provider.
final authProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(AuthNotifier.new);