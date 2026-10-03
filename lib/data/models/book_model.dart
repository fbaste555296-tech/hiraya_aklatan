import 'package:cloud_firestore/cloud_firestore.dart';

/// Book data model
class BookModel {
  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.summary,
    required this.genres,
    required this.coverUrl,
    required this.rating,
    this.ratingCount = 0,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String author;
  final String summary;
  final List<String> genres;
  final String coverUrl;
  final double rating;
  final int ratingCount;
  final String status;
  final DateTime createdAt;

  /// Creates a BookModel from Firestore document
  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    return BookModel(
      id: id,
      title: map['title'] as String,
      author: map['author'] as String,
      summary: map['summary'] as String,
      genres: List<String>.from(map['genres'] as List),
      coverUrl: map['coverUrl'] as String,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts BookModel to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'summary': summary,
      'genres': genres,
      'coverUrl': coverUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy with updated fields
  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? summary,
    List<String>? genres,
    String? coverUrl,
    double? rating,
    int? ratingCount,
    String? status,
    DateTime? createdAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      summary: summary ?? this.summary,
      genres: genres ?? this.genres,
      coverUrl: coverUrl ?? this.coverUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'BookModel(id: $id, title: $title, author: $author, status: $status)';
  }
}
