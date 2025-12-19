/// Result of a backup operation for a specific cloud provider
class BackupResult {
  /// The provider ID that this result belongs to
  final String providerId;
  
  /// Whether the backup operation was successful
  final bool success;
  
  /// The file ID if the backup was successful
  final String? fileId;
  
  /// The timestamp when the backup was completed
  final DateTime timestamp;
  
  /// Error message if the backup failed
  final String? error;
  
  /// Whether the checksum verification passed (if performed)
  final bool? checksumVerified;
  
  /// Size of the uploaded file in bytes
  final int? fileSize;

  BackupResult({
    required this.providerId,
    required this.success,
    this.fileId,
    required this.timestamp,
    this.error,
    this.checksumVerified,
    this.fileSize,
  });

  /// Create a successful backup result
  factory BackupResult.success({
    required String providerId,
    required String fileId,
    bool? checksumVerified,
    int? fileSize,
  }) {
    return BackupResult(
      providerId: providerId,
      success: true,
      fileId: fileId,
      timestamp: DateTime.now(),
      checksumVerified: checksumVerified,
      fileSize: fileSize,
    );
  }

  /// Create a failed backup result
  factory BackupResult.failure({
    required String providerId,
    required String error,
  }) {
    return BackupResult(
      providerId: providerId,
      success: false,
      timestamp: DateTime.now(),
      error: error,
    );
  }

  /// Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'success': success,
      'fileId': fileId,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'checksumVerified': checksumVerified,
      'fileSize': fileSize,
    };
  }

  /// Create from JSON
  factory BackupResult.fromJson(Map<String, dynamic> json) {
    return BackupResult(
      providerId: json['providerId'],
      success: json['success'],
      fileId: json['fileId'],
      timestamp: DateTime.parse(json['timestamp']),
      error: json['error'],
      checksumVerified: json['checksumVerified'],
      fileSize: json['fileSize'],
    );
  }

  @override
  String toString() {
    if (success) {
      return 'BackupResult($providerId: SUCCESS, fileId: $fileId, verified: $checksumVerified)';
    } else {
      return 'BackupResult($providerId: FAILED, error: $error)';
    }
  }
}
