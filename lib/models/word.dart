class Word {
  final int? id;
  final String wordEn;
  final String wordEs;
  final String pronunciation;
  final String? audioPath;
  final bool isLearned;
  final bool isSwiped;

  Word({
    this.id,
    required this.wordEn,
    required this.wordEs,
    required this.pronunciation,
    this.audioPath,
    this.isLearned = false,
    this.isSwiped = false,
  });

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      wordEn: map['word_en'] as String,
      wordEs: map['word_es'] as String,
      pronunciation: map['pronunciation'] as String,
      audioPath: map['audio_path'] as String?,
      isLearned: ((map['is_learned'] as int?) ?? 0) == 1,
      isSwiped: ((map['is_swiped'] as int?) ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word_en': wordEn,
      'word_es': wordEs,
      'pronunciation': pronunciation,
      'audio_path': audioPath,
      'is_learned': isLearned ? 1 : 0,
      'is_swiped': isSwiped ? 1 : 0,
    };
  }
}