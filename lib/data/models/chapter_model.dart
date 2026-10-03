import 'package:cloud_firestore/cloud_firestore.dart';

/// Chapter data model
class ChapterModel {
  const ChapterModel({
    required this.id,
    required this.bookId,
    required this.number,
    required this.title,
    required this.releaseDate,
    required this.isEarlyAccess,
    required this.price,
    required this.type,
  });

  final String id;
  final String bookId;
  final int number;
  final String title;
  final DateTime releaseDate;
  final bool isEarlyAccess;
  final double price;
  final String type; // 'text' or 'comic'

  /// Creates a ChapterModel from Firestore document
  factory ChapterModel.fromMap(Map<String, dynamic> map, String id, String bookId) {
    return ChapterModel(
      id: id,
      bookId: bookId,
      number: map['number'] as int,
      title: map['title'] as String,
      releaseDate: (map['releaseDate'] as Timestamp).toDate(),
      isEarlyAccess: map['isEarlyAccess'] as bool,
      price: (map['price'] as num).toDouble(),
      type: map['type'] as String,
    );
  }

  /// Converts ChapterModel to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'title': title,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'isEarlyAccess': isEarlyAccess,
      'price': price,
      'type': type,
    };
  }

  /// Creates a copy with updated fields
  ChapterModel copyWith({
    String? id,
    String? bookId,
    int? number,
    String? title,
    DateTime? releaseDate,
    bool? isEarlyAccess,
    double? price,
    String? type,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      number: number ?? this.number,
      title: title ?? this.title,
      releaseDate: releaseDate ?? this.releaseDate,
      isEarlyAccess: isEarlyAccess ?? this.isEarlyAccess,
      price: price ?? this.price,
      type: type ?? this.type,
    );
  }

  /// Checks if chapter is released
  bool get isReleased => releaseDate.isBefore(DateTime.now()) || releaseDate.isAtSameMomentAs(DateTime.now());

  /// Checks if chapter is free (released and not early access)
  bool get isFree => isReleased && !isEarlyAccess;

  /// Checks if chapter is locked (early access or not released)
  bool get isLocked => !isReleased || (isReleased && isEarlyAccess);

  @override
  String toString() {
    return 'ChapterModel(id: $id, bookId: $bookId, number: $number, title: $title, isEarlyAccess: $isEarlyAccess)';
  }
}
