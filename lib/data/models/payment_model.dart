import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment data model
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.userId,
    required this.type,
    this.targetId,
    this.bookId,
    this.planType,
    required this.amount,
    required this.referenceCode,
    required this.referenceNo,
    required this.proofUrl,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String userId;
  final String type; // 'chapter' or 'vip'
  final String? targetId; // chapterId for chapter payments
  final String? bookId; // bookId for chapter payments
  final String? planType; // 'monthly' or 'yearly' for VIP payments
  final double amount;
  final String referenceCode; // Generated code (HA-YYYYMMDD-XXXX)
  final String referenceNo; // User-provided transaction reference
  final String proofUrl; // Payment receipt screenshot
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminNote; // Note for rejection
  final DateTime createdAt;
  final DateTime? reviewedAt;

  /// Creates a PaymentModel from Firestore document
  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      userId: map['userId'] as String,
      type: map['type'] as String,
      targetId: map['targetId'] as String?,
      bookId: map['bookId'] as String?,
      planType: map['planType'] as String?,
      amount: (map['amount'] as num).toDouble(),
      referenceCode: map['referenceCode'] as String,
      referenceNo: map['referenceNo'] as String,
      proofUrl: map['proofUrl'] as String,
      status: map['status'] as String,
      adminNote: map['adminNote'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts PaymentModel to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      if (targetId != null) 'targetId': targetId,
      if (bookId != null) 'bookId': bookId,
      if (planType != null) 'planType': planType,
      'amount': amount,
      'referenceCode': referenceCode,
      'referenceNo': referenceNo,
      'proofUrl': proofUrl,
      'status': status,
      if (adminNote != null) 'adminNote': adminNote,
      'createdAt': Timestamp.fromDate(createdAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  /// Creates a copy with updated fields
  PaymentModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? targetId,
    String? bookId,
    String? planType,
    double? amount,
    String? referenceCode,
    String? referenceNo,
    String? proofUrl,
    String? status,
    String? adminNote,
    DateTime? createdAt,
    DateTime? reviewedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      bookId: bookId ?? this.bookId,
      planType: planType ?? this.planType,
      amount: amount ?? this.amount,
      referenceCode: referenceCode ?? this.referenceCode,
      referenceNo: referenceNo ?? this.referenceNo,
      proofUrl: proofUrl ?? this.proofUrl,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  /// Checks if payment is pending
  bool get isPending => status == 'pending';

  /// Checks if payment is approved
  bool get isApproved => status == 'approved';

  /// Checks if payment is rejected
  bool get isRejected => status == 'rejected';

  @override
  String toString() {
    return 'PaymentModel(id: $id, type: $type, amount: $amount, status: $status)';
  }
}
