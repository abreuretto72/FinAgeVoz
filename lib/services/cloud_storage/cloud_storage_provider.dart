import 'dart:typed_data';
import '../../models/backup_metadata.dart';

/// Abstract interface for cloud storage providers
/// All cloud backup services must implement this interface
abstract class CloudStorageProvider {
  /// Unique identifier for this provider (e.g., 'google_drive', 'onedrive')
  String get providerId;
  
  /// Human-readable name of the provider (e.g., 'Google Drive', 'OneDrive')
  String get providerName;
  
  /// Whether the user is currently signed in to this provider
  bool get isSignedIn;
  
  /// Email or username of the signed-in user (null if not signed in)
  String? get userEmail;
  
  /// Icon data for UI representation (optional)
  String? get iconAsset => null;
  
  /// Sign in to the cloud storage provider
  /// Returns true if sign-in was successful, false otherwise
  Future<bool> signIn();
  
  /// Sign out from the cloud storage provider
  Future<void> signOut();
  
  /// Upload a backup file to the cloud storage
  /// 
  /// [data] - The backup data as bytes
  /// [metadata] - Metadata about the backup (filename, size, counts, etc.)
  /// 
  /// Returns the file ID if successful, null otherwise
  Future<String?> uploadBackup(Uint8List data, BackupMetadata metadata);
  
  /// List all available backups in the cloud storage
  /// 
  /// Returns a list of backup metadata, sorted by creation date (newest first)
  Future<List<BackupMetadata>> listBackups();
  
  /// Download a specific backup file from the cloud storage
  /// 
  /// [fileId] - The unique identifier of the file to download
  /// 
  /// Returns the backup data as bytes
  Future<Uint8List> downloadBackup(String fileId);
  
  /// Delete a specific backup file from the cloud storage
  /// 
  /// [fileId] - The unique identifier of the file to delete
  Future<void> deleteBackup(String fileId);
  
  /// Verify the integrity of a backup file using checksum
  /// 
  /// [fileId] - The unique identifier of the file to verify
  /// [expectedHash] - The expected SHA-256 hash of the file
  /// 
  /// Returns true if the file's hash matches the expected hash
  Future<bool> verifyChecksum(String fileId, String expectedHash);
  
  /// Get the available storage space in bytes (optional)
  /// Returns null if not supported by the provider
  Future<int?> getAvailableSpace() async => null;
  
  /// Get the total storage space in bytes (optional)
  /// Returns null if not supported by the provider
  Future<int?> getTotalSpace() async => null;
}
