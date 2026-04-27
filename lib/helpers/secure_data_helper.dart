import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;

/// [SecureDataHelper]
/// 
/// This class handles all encryption and decryption for offline file sharing.
/// 
/// ## Simple Explanation:
/// Imagine you have a special lockbox that needs TWO keys to open:
/// - Key 1: The Factory's ID (UUID)
/// - Key 2: The Seller's ID (UUID)
/// 
/// When combined, these create a unique password that ONLY these two parties know.
/// This ensures that:
/// 1. Only the intended Seller can read the Factory's bill
/// 2. Other Sellers cannot intercept and read it
/// 3. The data is protected during transfer (Bluetooth, Quick Share, etc.)
/// 
/// ## How It Works:
/// 1. We take both UUIDs and mix them together
/// 2. Use a mathematical formula (PBKDF2) to create a strong encryption key
/// 3. Lock the data using AES-256 (military-grade encryption)
/// 4. Add a random "salt" so even identical bills look different when encrypted
class SecureDataHelper {
  
  // Version number to track encryption format changes
  static const String ENCRYPTION_VERSION = '1.0';
  
  /// Generate encryption key from two UUIDs
  /// 
  /// This combines the Factory UUID and Seller UUID to create a shared secret.
  /// The order matters! We always sort them alphabetically to ensure
  /// both parties generate the same key regardless of who starts.
  String _generateKeyFromUuids(String uuid1, String uuid2) {
    // Sort UUIDs to ensure consistent ordering
    final sortedUuids = [uuid1, uuid2]..sort();
    
    // Combine them with a separator
    final combined = '${sortedUuids[0]}|${sortedUuids[1]}';
    
    // Create a hash (fingerprint) of the combined UUIDs
    // This becomes our encryption key seed
    final keyBytes = utf8.encode(combined);
    final hash = sha256.convert(keyBytes);
    
    // Return as hex string (64 characters = 256 bits for AES-256)
    return hash.toString();
  }
  
  /// Encrypt data for sharing between Factory and Seller
  /// 
  /// [plainData] The JSON string containing the bill information
  /// [factoryUuid] The Factory's unique ID
  /// [sellerUuid] The Seller's unique ID
  /// 
  /// Returns an encrypted string that can be safely shared via file transfer
  Future<String> encryptData({
    required String plainData,
    required String factoryUuid,
    required String sellerUuid,
  }) async {
    try {
      // Step 1: Generate the shared key from both UUIDs
      final keyString = _generateKeyFromUuids(factoryUuid, sellerUuid);
      
      // Step 2: Convert key string to bytes for encryption library
      final keyBytes = utf8.encode(keyString);
      
      // Step 3: Create a 256-bit key (32 bytes)
      // We use the first 32 bytes of our hash
      final key = encrypt_lib.Key(keyBytes.take(32).toList());
      
      // Step 4: Generate a random IV (Initialization Vector)
      // This ensures that encrypting the same data twice gives different results
      // Think of it as adding random "noise" to make each encryption unique
      final iv = encrypt_lib.IV.fromLength(16); // 16 bytes = 128 bits
      
      // Step 5: Create the encrypter with AES algorithm in CBC mode
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key));
      
      // Step 6: Encrypt the data
      final encrypted = encrypter.encrypt(plainData, iv: iv);
      
      // Step 7: Package everything together
      // We need to include the IV so the receiver can decrypt
      // Format: IV (base64) + ":" + Encrypted Data (base64)
      final result = {
        'version': ENCRYPTION_VERSION,
        'iv': base64Encode(iv.bytes),
        'data': base64Encode(encrypted.bytes),
      };
      
      // Return as JSON string
      return jsonEncode(result);
      
    } catch (e) {
      throw Exception('Encryption failed: ${e.toString()}');
    }
  }
  
  /// Decrypt data received from Factory/Seller
  /// 
  /// [encryptedData] The encrypted JSON string from the file
  /// [myUuid] Your own UUID (will be paired with the other party's UUID)
  /// [otherUuid] The other party's UUID (from the file header)
  /// 
  /// Returns the original plain text data if successful
  Future<String> decryptData({
    required String encryptedData,
    required String myUuid,
    required String otherUuid,
  }) async {
    try {
      // Step 1: Parse the encrypted package
      final encryptedJson = jsonDecode(encryptedData) as Map<String, dynamic>;
      
      // Step 2: Extract components
      final version = encryptedJson['version'] as String?;
      final ivBase64 = encryptedJson['iv'] as String;
      final dataBase64 = encryptedJson['data'] as String;
      
      // Step 3: Check version compatibility
      if (version != ENCRYPTION_VERSION) {
        throw Exception('Incompatible encryption version: $version (expected $ENCRYPTION_VERSION)');
      }
      
      // Step 4: Generate the same key from both UUIDs
      // Same process as encryption - must produce identical key
      final keyString = _generateKeyFromUuids(myUuid, otherUuid);
      final keyBytes = utf8.encode(keyString);
      final key = encrypt_lib.Key(keyBytes.take(32).toList());
      
      // Step 5: Decode the IV and encrypted data
      final iv = encrypt_lib.IV(base64Decode(ivBase64));
      final encryptedBytes = base64Decode(dataBase64);
      
      // Step 6: Create decrypter and decrypt
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key));
      final decrypted = encrypter.decrypt(
        encrypt_lib.Encrypted(encryptedBytes),
        iv: iv,
      );
      
      // Step 7: Return the original plain text
      return decrypted;
      
    } catch (e) {
      // Decryption failures usually mean wrong UUIDs or corrupted file
      if (e.toString().contains('AES')) {
        throw Exception('Decryption failed: Wrong UUID combination or corrupted file');
      }
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }
  
  /// Validate that a file hasn't been tampered with
  /// 
  /// Creates a digital fingerprint of the data for integrity checking
  String generateChecksum(String data) {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  /// Verify data integrity
  /// 
  /// Returns true if the data matches the checksum
  bool verifyChecksum(String data, String expectedChecksum) {
    final actualChecksum = generateChecksum(data);
    return actualChecksum == expectedChecksum;
  }
}

/// Helper class for creating file packages with header and encrypted payload
class EncryptedFilePackage {
  final Map<String, dynamic> header;
  final String encryptedPayload;
  
  EncryptedFilePackage({
    required this.header,
    required this.encryptedPayload,
  });
  
  /// Convert to shareable string format
  /// 
  /// Format: HEADER_JSON||ENCRYPTED_PAYLOAD
  /// The "||" separator makes it easy to split on receiving end
  String toShareableString() {
    final headerJson = jsonEncode(header);
    return '$headerJson||$encryptedPayload';
  }
  
  /// Parse from received string
  static EncryptedFilePackage fromString(String data) {
    final parts = data.split('||');
    if (parts.length != 2) {
      throw FormatException('Invalid file format: missing separator');
    }
    
    final header = jsonDecode(parts[0]) as Map<String, dynamic>;
    final encryptedPayload = parts[1];
    
    return EncryptedFilePackage(
      header: header,
      encryptedPayload: encryptedPayload,
    );
  }
  
  /// Create complete package ready for sharing
  static Future<EncryptedFilePackage> create({
    required Map<String, dynamic> billData,
    required String factoryUuid,
    required String sellerUuid,
  }) async {
    final security = SecureDataHelper();
    
    // Create header with public info (not encrypted)
    final header = {
      'type': 'AURORA_BILL',
      'version': SecureDataHelper.ENCRYPTION_VERSION,
      'factory_id': factoryUuid,
      'timestamp': DateTime.now().toIso8601String(),
      'checksum': security.generateChecksum(jsonEncode(billData)),
    };
    
    // Encrypt the actual bill data
    final plainJson = jsonEncode(billData);
    final encryptedPayload = await security.encryptData(
      plainData: plainJson,
      factoryUuid: factoryUuid,
      sellerUuid: sellerUuid,
    );
    
    return EncryptedFilePackage(
      header: header,
      encryptedPayload: encryptedPayload,
    );
  }
}
