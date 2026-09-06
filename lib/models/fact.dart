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
    required this.isRead,
  });

  factory Fact.fromMap(Map<String, dynamic> map) {
    return Fact(
      id: map['id'] as int?,
      englishText: map['english_text'] as String,
      spanishTranslation: map['spanish_translation'] as String,
      difficultyLevel: map['difficulty'] as String,
      publishDate: map['publish_date'] as String,
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }

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
}
