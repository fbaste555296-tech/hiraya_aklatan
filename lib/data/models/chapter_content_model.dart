/// An ordered text or image section within chapter content.
class ChapterContentBlock {
  const ChapterContentBlock.text(this.text)
    : type = 'text',
      imageUrl = null;

  const ChapterContentBlock.image(this.imageUrl)
    : type = 'image',
      text = null;

  const ChapterContentBlock._({required this.type, this.text, this.imageUrl});

  final String type;
  final String? text;
  final String? imageUrl;

  factory ChapterContentBlock.fromMap(Map<String, dynamic> map) {
    return ChapterContentBlock._(
      type: map['type'] as String,
      text: map['text'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    if (text != null) 'text': text,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

/// Chapter content data model.
///
/// Content is stored separately from chapter metadata so locked content
/// can be protected by Firestore security rules.
class ChapterContentModel {
  const ChapterContentModel({
    required this.chapterId,
    required this.bookId,
    this.textContent,
    this.pageUrls,
    this.contentBlocks = const [],
  });

  final String chapterId;
  final String bookId;
  final String? textContent;
  final List<String>? pageUrls;
  final List<ChapterContentBlock> contentBlocks;

  bool get hasContentBlocks => contentBlocks.isNotEmpty;

  List<ChapterContentBlock> get orderedContent {
    if (hasContentBlocks) return contentBlocks;
    return <ChapterContentBlock>[
      if (textContent != null && textContent!.isNotEmpty)
        ChapterContentBlock.text(textContent!),
      if (pageUrls != null)
        ...pageUrls!.map(ChapterContentBlock.image),
    ];
  }

  /// Creates a ChapterContentModel from a Firestore document.
  factory ChapterContentModel.fromMap(
    Map<String, dynamic> map,
    String chapterId,
  ) {
    return ChapterContentModel(
      chapterId: chapterId,
      bookId: map['bookId'] as String,
      textContent: map['textContent'] as String?,
      pageUrls: map['pageUrls'] != null
          ? List<String>.from(map['pageUrls'] as List)
          : null,
      contentBlocks: map['contentBlocks'] != null
          ? (map['contentBlocks'] as List)
                .map(
                  (block) => ChapterContentBlock.fromMap(
                    Map<String, dynamic>.from(block as Map),
                  ),
                )
                .toList()
          : const [],
    );
  }

  /// Converts ChapterContentModel to a Firestore document.
  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      if (textContent != null) 'textContent': textContent,
      if (pageUrls != null) 'pageUrls': pageUrls,
      if (contentBlocks.isNotEmpty)
        'contentBlocks': contentBlocks.map((block) => block.toMap()).toList(),
    };
  }

  /// Creates a copy with updated fields.
  ChapterContentModel copyWith({
    String? chapterId,
    String? bookId,
    String? textContent,
    List<String>? pageUrls,
    List<ChapterContentBlock>? contentBlocks,
  }) {
    return ChapterContentModel(
      chapterId: chapterId ?? this.chapterId,
      bookId: bookId ?? this.bookId,
      textContent: textContent ?? this.textContent,
      pageUrls: pageUrls ?? this.pageUrls,
      contentBlocks: contentBlocks ?? this.contentBlocks,
    );
  }

  /// Checks if this is text content.
  bool get isText =>
      (textContent != null && textContent!.isNotEmpty) ||
      contentBlocks.any(
        (block) => block.type == 'text' && (block.text?.isNotEmpty ?? false),
      );

  /// Checks if this is comic content.
  bool get isComic =>
      (pageUrls != null && pageUrls!.isNotEmpty) ||
      contentBlocks.any(
        (block) => block.type == 'image' && (block.imageUrl?.isNotEmpty ?? false),
      );

  @override
  String toString() {
    return 'ChapterContentModel(chapterId: $chapterId, bookId: $bookId, '
        'isText: $isText, isComic: $isComic, '
        'contentBlocks: ${contentBlocks.length})';
  }
}
