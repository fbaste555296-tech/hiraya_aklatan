/// Chapter content data model (text or comic pages).
///
/// Content is stored separately from chapter metadata so locked content
/// can be protected by Firestore security rules.
class ChapterContentModel {
  const ChapterContentModel({
    required this.chapterId,
    required this.bookId,
    this.textContent,
    this.pageUrls,
  });

  final String chapterId;
  final String bookId;
  final String? textContent; // For text chapters
  final List<String>? pageUrls; // For comic chapters

  /// Creates a ChapterContentModel from a Firestore document.
  factory ChapterContentModel.fromMap(Map<String, dynamic> map, String chapterId) {
    return ChapterContentModel(
      chapterId: chapterId,
      bookId: map['bookId'] as String,
      textContent: map['textContent'] as String?,
      pageUrls: map['pageUrls'] != null
          ? List<String>.from(map['pageUrls'] as List)
          : null,
    );
  }

  /// Converts ChapterContentModel to a Firestore document.
  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      if (textContent != null) 'textContent': textContent,
      if (pageUrls != null) 'pageUrls': pageUrls,
    };
  }

  /// Creates a copy with updated fields.
  ChapterContentModel copyWith({
    String? chapterId,
    String? bookId,
    String? textContent,
    List<String>? pageUrls,
  }) {
    return ChapterContentModel(
      chapterId: chapterId ?? this.chapterId,
      bookId: bookId ?? this.bookId,
      textContent: textContent ?? this.textContent,
      pageUrls: pageUrls ?? this.pageUrls,
    );
  }

  /// Checks if this is text content.
  bool get isText => textContent != null && textContent!.isNotEmpty;

  /// Checks if this is comic content.
  bool get isComic => pageUrls != null && pageUrls!.isNotEmpty;

  @override
  String toString() {
    return 'ChapterContentModel(chapterId: $chapterId, bookId: $bookId, '
        'isText: $isText, isComic: $isComic)';
  }
}
