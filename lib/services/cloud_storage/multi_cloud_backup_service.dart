import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'cloud_storage_provider.dart';
import 'backup_logger.dart';
import '../../models/backup_metadata.dart';
import '../../models/backup_result.dart';
import '../../utils/checksum_util.dart';

/// Service for managing backups across multiple cloud storage providers
class MultiCloudBackupService {
  static final MultiCloudBackupService _instance = MultiCloudBackupService._internal();
  factory MultiCloudBackupService() => _instance;
  MultiCloudBackupService._internal();

  final List<CloudStorageProvider> _providers = [];
  final BackupLogger _logger = BackupLogger();

  /// Observable status
  final ValueNotifier<bool> isBackingUpNotifier = ValueNotifier(false);
  final ValueNotifier<Map<String, BackupResult>> lastBackupResultsNotifier = ValueNotifier({});

  /// Register a cloud storage provider
  void registerProvider(CloudStorageProvider provider) {
    if (!_providers.any((p) => p.providerId == provider.providerId)) {
      _providers.add(provider);
      print('MultiCloudBackup: Registered provider ${provider.providerName}');
    }
  }

  /// Unregister a cloud storage provider
  void unregisterProvider(String providerId) {
    _providers.removeWhere((p) => p.providerId == providerId);
    print('MultiCloudBackup: Unregistered provider $providerId');
  }

  /// Get all registered providers
  List<CloudStorageProvider> get providers => List.unmodifiable(_providers);

  /// Get signed-in providers only
  List<CloudStorageProvider> get signedInProviders {
    return _providers.where((p) => p.isSignedIn).toList();
  }

  /// Get a specific provider by ID
  CloudStorageProvider? getProvider(String providerId) {
    try {
      return _providers.firstWhere((p) => p.providerId == providerId);
    } catch (e) {
      return null;
    }
  }

  /// Backup to all signed-in providers (parallel execution)
  Future<Map<String, BackupResult>> backupToAll(
    Uint8List data,
    BackupMetadata metadata, {
    bool verifyChecksum = true,
  }) async {
    if (isBackingUpNotifier.value) {
      throw Exception('Backup already in progress');
    }

    isBackingUpNotifier.value = true;
    final results = <String, BackupResult>{};

    try {
      print('MultiCloudBackup: Starting backup to ${signedInProviders.length} providers');
      
      // Calculate checksum once for all providers
      final expectedHash = verifyChecksum ? ChecksumUtil.calculateSHA256(data) : null;

      // Backup to all providers in parallel
      await Future.wait(signedInProviders.map((provider) async {
        try {
          print('MultiCloudBackup: Uploading to ${provider.providerName}...');
          
          final fileId = await provider.uploadBackup(data, metadata);
          
          if (fileId == null) {
            throw Exception('Upload failed: fileId is null');
          }

          // Verify checksum if enabled
          bool? checksumVerified;
          if (verifyChecksum && expectedHash != null) {
            try {
              checksumVerified = await provider.verifyChecksum(fileId, expectedHash);
              if (!checksumVerified) {
                print('MultiCloudBackup: Checksum verification FAILED for ${provider.providerName}');
              }
            } catch (e) {
              print('MultiCloudBackup: Checksum verification error for ${provider.providerName}: $e');
              checksumVerified = false;
            }
          }

          final result = BackupResult.success(
            providerId: provider.providerId,
            fileId: fileId,
            checksumVerified: checksumVerified,
            fileSize: data.length,
          );

          results[provider.providerId] = result;
          _logger.logResult(result, BackupOperationType.upload);
          
          print('MultiCloudBackup: SUCCESS - ${provider.providerName}');
        } catch (e, stackTrace) {
          print('MultiCloudBackup: FAILED - ${provider.providerName}: $e');
          print('StackTrace: $stackTrace');
          
          final result = BackupResult.failure(
            providerId: provider.providerId,
            error: e.toString(),
          );
          
          results[provider.providerId] = result;
          _logger.logResult(result, BackupOperationType.upload);
        }
      }));

      lastBackupResultsNotifier.value = results;
      
      final successCount = results.values.where((r) => r.success).length;
      print('MultiCloudBackup: Completed - $successCount/${results.length} successful');
      
      return results;
    } finally {
      isBackingUpNotifier.value = false;
    }
  }

  /// Backup to a specific provider only
  Future<BackupResult> backupToProvider(
    String providerId,
    Uint8List data,
    BackupMetadata metadata, {
    bool verifyChecksum = true,
  }) async {
    final provider = getProvider(providerId);
    if (provider == null) {
      throw Exception('Provider $providerId not found');
    }

    if (!provider.isSignedIn) {
      throw Exception('Provider ${provider.providerName} is not signed in');
    }

    try {
      print('MultiCloudBackup: Uploading to ${provider.providerName}...');
      
      final fileId = await provider.uploadBackup(data, metadata);
      
      if (fileId == null) {
        throw Exception('Upload failed: fileId is null');
      }

      // Verify checksum if enabled
      bool? checksumVerified;
      if (verifyChecksum) {
        final expectedHash = ChecksumUtil.calculateSHA256(data);
        checksumVerified = await provider.verifyChecksum(fileId, expectedHash);
      }

      final result = BackupResult.success(
        providerId: provider.providerId,
        fileId: fileId,
        checksumVerified: checksumVerified,
        fileSize: data.length,
      );

      _logger.logResult(result, BackupOperationType.upload);
      return result;
    } catch (e) {
      final result = BackupResult.failure(
        providerId: provider.providerId,
        error: e.toString(),
      );
      
      _logger.logResult(result, BackupOperationType.upload);
      return result;
    }
  }

  /// List backups from all providers
  Future<Map<String, List<BackupMetadata>>> listAllBackups() async {
    final allBackups = <String, List<BackupMetadata>>{};

    await Future.wait(signedInProviders.map((provider) async {
      try {
        final backups = await provider.listBackups();
        allBackups[provider.providerId] = backups;
        
        _logger.log(BackupLogEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          providerId: provider.providerId,
          timestamp: DateTime.now(),
          success: true,
          operationType: BackupOperationType.list,
        ));
      } catch (e) {
        print('MultiCloudBackup: Failed to list backups from ${provider.providerName}: $e');
        allBackups[provider.providerId] = [];
        
        _logger.log(BackupLogEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          providerId: provider.providerId,
          timestamp: DateTime.now(),
          success: false,
          error: e.toString(),
          operationType: BackupOperationType.list,
        ));
      }
    }));

    return allBackups;
  }

  /// Restore from the most recent backup across all providers
  Future<Uint8List?> restoreFromBest() async {
    final allBackups = await listAllBackups();
    
    // Find the most recent backup
    BackupMetadata? mostRecent;
    String? bestProviderId;

    for (var entry in allBackups.entries) {
      final backups = entry.value;
      if (backups.isEmpty) continue;

      final latest = backups.first; // Assuming sorted by date desc
      if (mostRecent == null || latest.createdAt.isAfter(mostRecent.createdAt)) {
        mostRecent = latest;
        bestProviderId = entry.key;
      }
    }

    if (mostRecent == null || bestProviderId == null) {
      print('MultiCloudBackup: No backups found');
      return null;
    }

    print('MultiCloudBackup: Restoring from ${getProvider(bestProviderId)?.providerName} (${mostRecent.fileName})');
    
    final provider = getProvider(bestProviderId)!;
    return await provider.downloadBackup(mostRecent.id);
  }

  /// Get backup logger
  BackupLogger get logger => _logger;

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};
    
    for (var provider in _providers) {
      stats[provider.providerId] = {
        'name': provider.providerName,
        'signedIn': provider.isSignedIn,
        'successRate': _logger.getSuccessRate(provider.providerId),
      };
    }
    
    return stats;
  }
}
