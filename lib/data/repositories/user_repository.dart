import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Repository for user data operations
class UserRepository {
  UserRepository({required this._firestoreService});

  final FirestoreService _firestoreService;

  /// Gets a user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestoreService.users.doc(uid).get();

      if (!doc.exists) return null;

      return UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  /// Stream of user data
  Stream<UserModel?> watchUser(String uid) {
    return _firestoreService.users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  /// Updates user profile
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestoreService.users.doc(uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  /// Updates user's VIP expiry date
  Future<void> updateVipExpiry(String uid, DateTime? vipExpiry) async {
    try {
      await _firestoreService.users.doc(uid).update({
        'vipExpiry': vipExpiry != null ? Timestamp.fromDate(vipExpiry) : null,
      });
    } catch (e) {
      throw Exception('Failed to update VIP expiry: ${e.toString()}');
    }
  }

  /// Gets all users (admin only)
  Future<List<UserModel>> getAllUsers({
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = _firestoreService.users;

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: ${e.toString()}');
    }
  }

  /// Searches users by name or email
  Future<List<UserModel>> searchUsers(String searchTerm) async {
    try {
      // Note: This is a simple implementation
      // For production, consider using Algolia or similar search service
      final snapshot = await _firestoreService.users.get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      final lowerSearch = searchTerm.toLowerCase();
      return users.where((user) {
        return user.name.toLowerCase().contains(lowerSearch) ||
            user.email.toLowerCase().contains(lowerSearch);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search users: ${e.toString()}');
    }
  }

  /// Checks if user has active VIP subscription
  Future<bool> hasActiveVip(String uid) async {
    try {
      final user = await getUserById(uid);
      if (user == null) return false;
      return user.isVipActive;
    } catch (e) {
      throw Exception('Failed to check VIP status: ${e.toString()}');
    }
  }

  /// Gets VIP users count
  Future<int> getVipUsersCount() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestoreService.users
          .where('vipExpiry', isGreaterThan: now)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get VIP users count: ${e.toString()}');
    }
  }
}
