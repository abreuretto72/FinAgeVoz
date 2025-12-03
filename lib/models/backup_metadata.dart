class BackupMetadata {
  final String id;
  final String fileName;
  final DateTime createdAt;
  final int fileSize;
  final int transactionCount;
  final int eventCount;
  final DateTime? startDate;
  final DateTime? endDate;

  BackupMetadata({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.fileSize,
    required this.transactionCount,
    required this.eventCount,
    this.startDate,
    this.endDate,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String toDescription() {
    return '$transactionCount|$eventCount|${startDate?.toIso8601String() ?? ''}|${endDate?.toIso8601String() ?? ''}';
  }
}
