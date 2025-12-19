import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Utility class for calculating and verifying checksums
class ChecksumUtil {
  /// Calculate SHA-256 hash of data
  static String calculateSHA256(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// Calculate MD5 hash of data (faster but less secure)
  static String calculateMD5(Uint8List data) {
    final digest = md5.convert(data);
    return digest.toString();
  }

  /// Verify that data matches expected SHA-256 hash
  static bool verifySHA256(Uint8List data, String expectedHash) {
    final actualHash = calculateSHA256(data);
    return actualHash.toLowerCase() == expectedHash.toLowerCase();
  }

  /// Verify that data matches expected MD5 hash
  static bool verifyMD5(Uint8List data, String expectedHash) {
    final actualHash = calculateMD5(data);
    return actualHash.toLowerCase() == expectedHash.toLowerCase();
  }

  /// Calculate hash of a string
  static String hashString(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Generate a quick checksum for integrity verification
  /// Uses first 1MB of data for large files (performance optimization)
  static String quickChecksum(Uint8List data, {int maxBytes = 1024 * 1024}) {
    if (data.length <= maxBytes) {
      return calculateSHA256(data);
    }
    
    // For large files, hash first MB + last MB + file size
    final firstChunk = data.sublist(0, maxBytes ~/ 2);
    final lastChunk = data.sublist(data.length - (maxBytes ~/ 2));
    final combined = Uint8List.fromList([
      ...firstChunk,
      ...lastChunk,
      ...utf8.encode(data.length.toString()),
    ]);
    
    return calculateSHA256(combined);
  }
}
