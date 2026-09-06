class Tip {
  final int? id;
  final String title;
  final String content;
  final String category;

  Tip({
    this.id,
    required this.title,
    required this.content,
    required this.category,
  });

  factory Tip.fromMap(Map<String, dynamic> map) {
    return Tip(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
    };
  }
}
