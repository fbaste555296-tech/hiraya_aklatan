// lib/features/auth/viewmodels/current_user_viewmodel.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/providers/service_providers.dart';

/// ViewModel for managing the current user's profile state.
///
/// Handles loading, error, and data states for the user's Firestore document.
class CurrentUserViewModel extends Notifier<AsyncValue<UserModel?>> {
  @override
  AsyncValue<UserModel?> build() {
    return ref.watch(currentUserStreamProvider);
  }

  /// Refreshes the current user's profile from Firestore.
  Future<void> refresh() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    final userRepository = ref.read(userRepositoryProvider);
    state = await AsyncValue.guard(() => userRepository.getUserById(firebaseUser.uid));
  }

  /// Updates the current user's profile in Firestore.
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('No user signed in');
    }

    state = const AsyncValue.loading();
    final userRepository = ref.read(userRepositoryProvider);
    await userRepository.updateUser(firebaseUser.uid, updates);
    await refresh();
  }
}

/// Provider for the CurrentUserViewModel.
final currentUserViewModelProvider =
    NotifierProvider<CurrentUserViewModel, AsyncValue<UserModel?>>(CurrentUserViewModel.new);

/// Convenience provider that exposes just the user data (for backward compatibility).
final currentUserProvider = Provider<AsyncValue<UserModel?>>((ref) {
  return ref.watch(currentUserViewModelProvider);
});

/// Whether the current user is an admin.
final isAdminProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserViewModelProvider);
  return currentUser.maybeWhen(
    data: (user) => user?.isAdmin ?? false,
    orElse: () => false,
  );
});

/// Whether the current user has an active VIP subscription.
final isVipProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserViewModelProvider);
  return currentUser.maybeWhen(
    data: (user) => user?.isVipActive ?? false,
    orElse: () => false,
  );
});

/// Whether a Firebase user is currently signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final firebaseUser = ref.watch(firebaseUserProvider);
  return firebaseUser.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// Stream of the raw Firebase auth user (null when signed out).
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// StreamProvider for the current user's Firestore document.
///
/// This provider watches the user's Firestore document and emits
/// UserModel? as the stream emits values.
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final firebaseUser = ref.watch(firebaseUserProvider);

  return switch (firebaseUser) {
    AsyncData(:final value) => value == null
        ? Stream.value(null)
        : ref.watch(userRepositoryProvider).watchUser(value.uid),
    AsyncLoading() => const Stream.empty(),
    AsyncError(:final error, :final stackTrace) => Stream.error(error, stackTrace),
  };
});

/// Provider that exposes the current user from the stream provider.
final currentUserFromStreamProvider = Provider<AsyncValue<UserModel?>>((ref) {
  return ref.watch(currentUserStreamProvider);
});