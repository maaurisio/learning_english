class BilingualItem {
  final int? id;
  final String englishText;
  final String spanishTranslation;
  final String category;

  BilingualItem({
    this.id,
    required this.englishText,
    required this.spanishTranslation,
    required this.category,
  });

  factory BilingualItem.fromMap(Map<String, dynamic> map, {String englishKey = 'english_text', String spanishKey = 'spanish_translation', String categoryKey = 'category'}) {
    return BilingualItem(
      id: map['id'] as int?,
      englishText: map[englishKey] as String,
      spanishTranslation: map[spanishKey] as String,
      category: map[categoryKey] as String,
    );
  }

  Map<String, dynamic> toMap({String englishKey = 'english_text', String spanishKey = 'spanish_translation', String categoryKey = 'category'}) {
    return {
      'id': id,
      englishKey: englishText,
      spanishKey: spanishTranslation,
      categoryKey: category,
    };
  }
}