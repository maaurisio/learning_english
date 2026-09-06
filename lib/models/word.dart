class Word {
  final int? id;
  final String wordEn;
  final String wordEs;
  final String pronunciation;
  final String? audioPath;

  Word({
    this.id,
    required this.wordEn,
    required this.wordEs,
    required this.pronunciation,
    this.audioPath,
  });

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      wordEn: map['word_en'] as String,
      wordEs: map['word_es'] as String,
      pronunciation: map['pronunciation'] as String,
      audioPath: map['audio_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word_en': wordEn,
      'word_es': wordEs,
      'pronunciation': pronunciation,
      'audio_path': audioPath,
    };
  }
}
