import 'dart:convert';
import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import '../models/backup_metadata.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  bool get isSignedIn => _currentUser != null;
  String? get userEmail => _currentUser?.email;

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      _currentUser = account;
      
      // Get authentication headers
      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      
      _driveApi = drive.DriveApi(authenticateClient);
      
      return true;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  Future<String?> uploadBackup(Uint8List data, BackupMetadata metadata) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      // Create file metadata
      final driveFile = drive.File()
        ..name = metadata.fileName
        ..description = '${metadata.transactionCount}|${metadata.eventCount}|${metadata.startDate?.toIso8601String()}|${metadata.endDate?.toIso8601String()}'
        ..mimeType = metadata.fileName.endsWith('.zip') ? 'application/zip' : 'application/json'
        ..parents = ['appDataFolder']; // Store in app's private folder

      final media = drive.Media(Stream.value(data), data.length);

      // Upload file
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      return uploadedFile.id;
    } catch (e) {
      print('Error uploading backup: $e');
      rethrow;
    }
  }

  Future<List<BackupMetadata>> listBackups() async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final fileList = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "(mimeType='application/json' or mimeType='application/zip') and name contains 'finagevoz_backup'",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, description, size, createdTime)',
      );

      final backups = <BackupMetadata>[];
      for (var file in fileList.files ?? []) {
        // Parse metadata from description
        final parts = file.description?.split('|') ?? [];
        backups.add(BackupMetadata(
          id: file.id!,
          fileName: file.name!,
          createdAt: file.createdTime ?? DateTime.now(),
          fileSize: int.tryParse(file.size ?? '0') ?? 0,
          transactionCount: parts.length > 0 ? int.tryParse(parts[0]) ?? 0 : 0,
          eventCount: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
          startDate: parts.length > 2 ? DateTime.tryParse(parts[2]) : null,
          endDate: parts.length > 3 ? DateTime.tryParse(parts[3]) : null,
        ));
      }

      return backups;
    } catch (e) {
      print('Error listing backups: $e');
      rethrow;
    }
  }

  Future<Uint8List> downloadBackup(String fileId) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (var chunk in media.stream) {
        bytes.addAll(chunk);
      }

      return Uint8List.fromList(bytes);
    } catch (e) {
      print('Error downloading backup: $e');
      rethrow;
    }
  }

  Future<void> deleteBackup(String fileId) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      await _driveApi!.files.delete(fileId);
    } catch (e) {
      print('Error deleting backup: $e');
      rethrow;
    }
  }
}

// Helper class for authenticated HTTP client
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
