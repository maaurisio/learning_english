class OfflineDownload {
  final int? id;
  final String downloadDate;
  final String dataPackageName;
  final int wordCount;

  OfflineDownload({
    this.id,
    required this.downloadDate,
    required this.dataPackageName,
    this.wordCount = 0,
  });

  factory OfflineDownload.fromMap(Map<String, dynamic> map) {
    return OfflineDownload(
      id: map['id'] as int?,
      downloadDate: map['download_date'] as String,
      dataPackageName: map['data_package_name'] as String,
      wordCount: map['word_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'download_date': downloadDate,
      'data_package_name': dataPackageName,
      'word_count': wordCount,
    };
  }
}
