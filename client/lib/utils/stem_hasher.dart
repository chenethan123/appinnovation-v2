import 'dart:convert';
import 'package:crypto/crypto.dart';

class StemHasher {
  /// Normalize and hash a question stem for deduplication
  static String hashStem(String stem) {
    // Normalize the stem
    final normalized = _normalize(stem);
    
    // Generate SHA-256 hash
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
  
  /// Normalize stem by removing punctuation, extra whitespace, and converting to lowercase
  static String _normalize(String stem) {
    return stem
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ')    // Collapse whitespace
        .trim();
  }
  
  /// Check if two stems are similar (same normalized hash)
  static bool areSimilar(String stem1, String stem2) {
    return hashStem(stem1) == hashStem(stem2);
  }
}
