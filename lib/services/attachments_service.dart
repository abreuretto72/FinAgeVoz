import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class AttachmentsService {
  static const Uuid _uuid = Uuid();

  /// Saves a file to the application's document directory
  /// Returns the path of the saved file
  static Future<String> saveAttachment(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(path.join(appDir.path, 'attachments'));
    
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final extension = path.extension(file.path);
    final fileName = '${_uuid.v4()}$extension';
    final savedFile = await file.copy(path.join(attachmentsDir.path, fileName));
    
    return savedFile.path;
  }

  /// Deletes an attachment file
  static Future<void> deleteAttachment(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Gets the file name from a path
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }
}
