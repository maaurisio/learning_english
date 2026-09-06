class Fact {
  final int? id;
  final String englishText;
  final String spanishTranslation;
  final String difficultyLevel;
  final String publishDate;
  final bool isRead;

  Fact({
    this.id,
    required this.englishText,
    required this.spanishTranslation,
    required this.difficultyLevel,
    required this.publishDate,
    this.isRead = false,
  });

  Fact.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        englishText = map['english_text'] as String,
        spanishTranslation = map['spanish_translation'] as String,
        difficultyLevel = map['difficulty'] as String,
        publishDate = map['publish_date'] as String,
        isRead = (map['is_read'] as int) == 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'english_text': englishText,
      'spanish_translation': spanishTranslation,
      'difficulty': difficultyLevel,
      'publish_date': publishDate,
      'is_read': isRead ? 1 : 0,
    };
  }

  Fact copyWith({
    int? id,
    String? englishText,
    String? spanishTranslation,
    String? difficultyLevel,
    String? publishDate,
    bool? isRead,
  }) {
    return Fact(
      id: id ?? this.id,
      englishText: englishText ?? this.englishText,
      spanishTranslation: spanishTranslation ?? this.spanishTranslation,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      publishDate: publishDate ?? this.publishDate,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'Fact(id: $id, englishText: $englishText, difficultyLevel: $difficultyLevel, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
