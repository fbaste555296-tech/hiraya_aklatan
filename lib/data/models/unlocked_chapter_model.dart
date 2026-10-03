import 'package:cloud_firestore/cloud_firestore.dart';

/// Unlocked chapter record model
class UnlockedChapterModel {
  const UnlockedChapterModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.chapterId,
    required this.paymentId,
    required this.unlockedAt,
  });

  final String id;
  final String userId;
  final String bookId;
  final String chapterId;
  final String paymentId;
  final DateTime unlockedAt;

  /// Creates an UnlockedChapterModel from Firestore document
  factory UnlockedChapterModel.fromMap(Map<String, dynamic> map, String id) {
    return UnlockedChapterModel(
      id: id,
      userId: map['userId'] as String,
      bookId: map['bookId'] as String,
      chapterId: map['chapterId'] as String,
      paymentId: map['paymentId'] as String,
      unlockedAt: (map['unlockedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts UnlockedChapterModel to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'chapterId': chapterId,
      'paymentId': paymentId,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
    };
  }

  /// Creates a copy with updated fields
  UnlockedChapterModel copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? chapterId,
    String? paymentId,
    DateTime? unlockedAt,
  }) {
    return UnlockedChapterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      paymentId: paymentId ?? this.paymentId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  String toString() {
    return 'UnlockedChapterModel(id: $id, userId: $userId, chapterId: $chapterId)';
  }
}
