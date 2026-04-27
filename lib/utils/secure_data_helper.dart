import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:crypto/crypto.dart';

/// **SecureDataHelper**
/// 
/// **What does this do?**
/// This file handles the locking and unlocking of data shared between 
/// the Factory and the Seller.
///
/// **How it works (Simple Explanation):**
/// 1. **The Key**: We take the Factory's ID and the Seller's ID, mix them together, 
///    and create a secret password (Key). Only these two specific users can create this exact key.
/// 2. **Locking (Encrypt)**: When the Factory creates a bill, we turn the bill into a secret code 
///    using that key. Even if someone else intercepts the file, they only see gibberish.
/// 3. **Unlocking (Decrypt)**: When the Seller receives the file, their app uses their own ID 
///    and the Factory's ID to recreate the same key. If the IDs match, the lock opens, 
///    and the bill becomes readable again.
///
/// **Why do we do this?**
/// To ensure privacy. Only the intended Seller can read the bill from the intended Factory.
class SecureDataHelper {
  
  /// Generates a secure 32-byte key from two UUIDs (Factory & Seller).
  /// We combine them and hash them (SHA-256) to ensure the key is always 
  /// the same for this specific pair, but random enough to be secure.
  static encrypt_lib.Key _generateKey(String uuid1, String uuid2) {
    // Sort UUIDs to ensure order doesn't matter (A+B == B+A)
    final List<String> sortedUuids = [uuid1, uuid2]..sort();
    final String combined = sortedUuids.join(':');
    
    // Create SHA-256 hash -> 32 bytes perfect for AES-256
    final digest = sha256.convert(utf8.encode(combined));
    return encrypt_lib.Key(digest.bytes);
  }

  /// **Locks the data**
  /// Takes any object (like a Bill), converts it to text, and scrambles it.
  /// Returns a base64 string that looks like random noise.
  static String encryptData(dynamic data, String factoryUuid, String sellerUuid) {
    try {
      final key = _generateKey(factoryUuid, sellerUuid);
      final iv = encrypt_lib.IV.fromLength(16); // Random initialization vector
      
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key));
      
      // Convert data to JSON string
      final jsonString = jsonEncode(data);
      
      // Encrypt
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      
      // Return IV + Encrypted Data combined (needed for decryption)
      return '${base64Encode(iv.bytes)}:${base64Encode(encrypted.bytes)}';
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// **Unlocks the data**
  /// Takes the scrambled text and the two UUIDs. If they are the correct pair,
  /// it unscrambles the text back into the original object.
  static dynamic decryptData(String encryptedPayload, String factoryUuid, String sellerUuid) {
    try {
      final key = _generateKey(factoryUuid, sellerUuid);
      
      // Split IV and Encrypted Data
      final parts = encryptedPayload.split(':');
      if (parts.length != 2) throw Exception('Invalid payload format');
      
      final iv = encrypt_lib.IV(base64Decode(parts[0]));
      final encryptedBytes = base64Decode(parts[1]);
      final encrypted = encrypt_lib.Encrypted(encryptedBytes);
      
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key));
      
      // Decrypt
      final decryptedJson = encrypter.decrypt(encrypted, iv: iv);
      
      // Convert back to Object
      return jsonDecode(decryptedJson);
    } catch (e) {
      throw Exception('Decryption failed: Invalid Key or Corrupted Data. Ensure both users are correct.');
    }
  }
}
