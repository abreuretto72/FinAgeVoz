import '../models/backup_result.dart';

/// Entry in the backup log
class BackupLogEntry {
  /// Unique identifier for this log entry
  final String id;
  
  /// The provider ID that this log entry belongs to
  final String providerId;
  
  /// Timestamp when the backup operation occurred
  final DateTime timestamp;
  
  /// Whether the backup was successful
  final bool success;
  
  /// Error message if the backup failed
  final String? error;
  
  /// File ID if the backup was successful
  final String? fileId;
  
  /// Size of the backup file in bytes
  final int? fileSize;
  
  /// Whether checksum verification passed
  final bool? checksumVerified;
  
  /// Type of operation (upload, download, delete, verify)
  final BackupOperationType operationType;

  BackupLogEntry({
    required this.id,
    required this.providerId,
    required this.timestamp,
    required this.success,
    this.error,
    this.fileId,
    this.fileSize,
    this.checksumVerified,
    required this.operationType,
  });

  /// Create from BackupResult
  factory BackupLogEntry.fromResult(
    BackupResult result,
    BackupOperationType operationType,
  ) {
    return BackupLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      providerId: result.providerId,
      timestamp: result.timestamp,
      success: result.success,
      error: result.error,
      fileId: result.fileId,
      fileSize: result.fileSize,
      checksumVerified: result.checksumVerified,
      operationType: operationType,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'error': error,
      'fileId': fileId,
      'fileSize': fileSize,
      'checksumVerified': checksumVerified,
      'operationType': operationType.toString(),
    };
  }

  /// Create from JSON
  factory BackupLogEntry.fromJson(Map<String, dynamic> json) {
    return BackupLogEntry(
      id: json['id'],
      providerId: json['providerId'],
      timestamp: DateTime.parse(json['timestamp']),
      success: json['success'],
      error: json['error'],
      fileId: json['fileId'],
      fileSize: json['fileSize'],
      checksumVerified: json['checksumVerified'],
      operationType: BackupOperationType.values.firstWhere(
        (e) => e.toString() == json['operationType'],
        orElse: () => BackupOperationType.upload,
      ),
    );
  }
}

/// Type of backup operation
enum BackupOperationType {
  upload,
  download,
  delete,
  verify,
  list,
}

/// Service for logging backup operations
class BackupLogger {
  static final BackupLogger _instance = BackupLogger._internal();
  factory BackupLogger() => _instance;
  BackupLogger._internal();

  final List<BackupLogEntry> _logs = [];
  final int _maxLogs = 500; // Keep last 500 logs

  /// Add a log entry
  void log(BackupLogEntry entry) {
    _logs.insert(0, entry); // Add to beginning (newest first)
    
    // Trim old logs
    if (_logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs, _logs.length);
    }
    
    print('BACKUP LOG [${entry.providerId}]: ${entry.success ? "SUCCESS" : "FAILED"} - ${entry.operationType}');
    if (entry.error != null) {
      print('  Error: ${entry.error}');
    }
  }

  /// Log a backup result
  void logResult(BackupResult result, BackupOperationType operationType) {
    log(BackupLogEntry.fromResult(result, operationType));
  }

  /// Get recent logs
  List<BackupLogEntry> getRecentLogs({int limit = 50}) {
    return _logs.take(limit).toList();
  }

  /// Get logs for a specific provider
  List<BackupLogEntry> getLogsForProvider(String providerId, {int limit = 50}) {
    return _logs
        .where((log) => log.providerId == providerId)
        .take(limit)
        .toList();
  }

  /// Get logs for a specific operation type
  List<BackupLogEntry> getLogsByType(BackupOperationType type, {int limit = 50}) {
    return _logs
        .where((log) => log.operationType == type)
        .take(limit)
        .toList();
  }

  /// Get failed logs only
  List<BackupLogEntry> getFailedLogs({int limit = 50}) {
    return _logs
        .where((log) => !log.success)
        .take(limit)
        .toList();
  }

  /// Get success rate for a provider
  double getSuccessRate(String providerId) {
    final providerLogs = _logs.where((log) => log.providerId == providerId).toList();
    if (providerLogs.isEmpty) return 0.0;
    
    final successCount = providerLogs.where((log) => log.success).length;
    return successCount / providerLogs.length;
  }

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
  }

  /// Export logs as JSON
  List<Map<String, dynamic>> exportLogsAsJson() {
    return _logs.map((log) => log.toJson()).toList();
  }

  /// Import logs from JSON
  void importLogsFromJson(List<Map<String, dynamic>> jsonLogs) {
    _logs.clear();
    for (var json in jsonLogs) {
      try {
        _logs.add(BackupLogEntry.fromJson(json));
      } catch (e) {
        print('Error importing log entry: $e');
      }
    }
  }
}
