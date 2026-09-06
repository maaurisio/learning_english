class UserProgress {
  final int? id;
  final int wordsCorrect;
  final int totalTests;
  final String lastSessionDate;

  UserProgress({
    this.id,
    this.wordsCorrect = 0,
    this.totalTests = 0,
    required this.lastSessionDate,
  });

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      id: map['id'] as int?,
      wordsCorrect: map['words_correct'] as int? ?? 0,
      totalTests: map['total_tests'] as int? ?? 0,
      lastSessionDate: map['last_session_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'words_correct': wordsCorrect,
      'total_tests': totalTests,
      'last_session_date': lastSessionDate,
    };
  }
}
