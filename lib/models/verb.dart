class Verb {
  final int? id;
  final String base;
  final String present;
  final String past;
  final String future;
  final String translation;

  Verb({
    this.id,
    required this.base,
    required this.present,
    required this.past,
    required this.future,
    required this.translation,
  });

  factory Verb.fromMap(Map<String, dynamic> map) {
    return Verb(
      id: map['id'] as int?,
      base: map['base'] as String,
      present: map['present'] as String,
      past: map['past'] as String,
      future: map['future'] as String,
      translation: map['translation'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'base': base,
      'present': present,
      'past': past,
      'future': future,
      'translation': translation,
    };
  }
}