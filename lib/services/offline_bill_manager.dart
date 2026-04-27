import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/secure_data_helper.dart';
import '../models/bill_model.dart';

/// **OfflineBillManager**
/// 
/// **What does this do?**
/// This handles the entire flow of creating a bill, locking it, sharing it via Quick Share/Nearby Share,
/// and then reading it back on the Seller's device.
///
/// **The Flow:**
/// 1. Factory selects products & quantity for a specific Seller.
/// 2. We create a "Bill" object.
/// 3. We lock (encrypt) the Bill using both UUIDs.
/// 4. We save it as a `.aurora` file (CSV-like but secure).
/// 5. We trigger the system share sheet (Quick Share/Bluetooth).
/// 6. Seller receives file -> App detects `.aurora` -> Unlocks with their UUID -> Adds to "Imports".

class OfflineBillManager {

  /// Creates a bill object from selected products
  static BillModel createBill({
    required String factoryUuid,
    required String sellerUuid,
    required List<BillItem> items,
    required String paymentMethod,
    String? notes,
  }) {
    final DateTime timestamp = DateTime.now();
    
    double totalAmount = 0;
    for (var item in items) {
      totalAmount += item.totalPrice;
    }

    return BillModel(
      billId: DateTime.now().millisecondsSinceEpoch.toString(),
      factoryUuid: factoryUuid,
      sellerUuid: sellerUuid,
      timestamp: timestamp,
      items: items,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }

  /// Encrypts the bill and prepares it for sharing
  static Future<void> shareBillWithSeller({
    required BillModel bill,
    required String factoryUuid,
    required String sellerUuid,
  }) async {
    try {
      // 1. Convert BillModel to JSON
      final Map<String, dynamic> billData = bill.toJson();
      
      // 2. Encrypt the data using both UUIDs as the key
      final String encryptedContent = SecureDataHelper.encryptData(
        billData, 
        factoryUuid, 
        sellerUuid
      );

      // 3. Create a CSV-like structure with header, factory UUID, and payload
      // Format: AURORA_V1,FACTORY_UUID,ENCRYPTED_PAYLOAD
      final String csvContent = 'AURORA_V1,$factoryUuid,$encryptedContent';

      // 4. Save to a temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'bill_${bill.billId}.aurora';
      final File file = File('${tempDir.path}/$fileName');
      
      await file.writeAsString(csvContent);

      // 5. Trigger System Share (Quick Share, Nearby Share, Bluetooth, etc.)
      final XFile xFile = XFile(file.path, name: fileName, mimeType: 'text/plain');
      
      await Share.shareXFiles(
        [xFile],
        subject: 'Wholesale Bill from Factory',
        text: 'Here is your wholesale bill. Open with Aurora App to import.',
      );

      // Optional: Delete temp file after sharing if needed, 
      // though OS usually cleans temp dir
    } catch (e) {
      throw Exception('Failed to share bill: $e');
    }
  }

  /// Reads a received .aurora file, decrypts it, and returns the BillModel
  /// This is called when a Seller picks a file from their file manager or share target
  static Future<BillModel?> importBillFromFile({
    required String sellerUuid,
  }) async {
    try {
      // 1. Let user pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['aurora', 'csv', 'txt'],
      );

      if (result == null || result.files.single.path == null) {
        return null; // User cancelled
      }

      final String filePath = result.files.single.path!;
      final File file = File(filePath);
      
      // 2. Read the content
      final String content = await file.readAsString();
      
      // 3. Validate Header (Simple CSV check)
      final List<String> lines = content.split('\n');
      if (lines.isEmpty || !lines[0].startsWith('AURORA_V1')) {
        throw Exception('Invalid file format. Not an Aurora Bill.');
      }

      // 4. Parse CSV: AURORA_V1,FACTORY_UUID,ENCRYPTED_PAYLOAD
      final List<String> parts = lines[0].split(',');
      if (parts.length < 3) {
         throw Exception('Corrupted file: Missing Factory ID or Payload');
      }
      
      final String factoryUuid = parts[1];
      final String encryptedPayload = parts[2];

      // 5. Decrypt using Seller UUID + Factory UUID
      final dynamic decryptedData = SecureDataHelper.decryptData(
        encryptedPayload,
        factoryUuid,
        sellerUuid
      );

      // 6. Convert to BillModel
      return BillModel.fromJson(decryptedData as Map<String, dynamic>);

    } catch (e) {
      print('Import error: $e');
      rethrow; // Or show user friendly error
    }
  }
  
  /// Helper to process the imported bill into the local database
  /// This converts the BillModel into local Order/Product records
  static Future<void> processImportedBill({
    required BillModel bill,
    required String sellerUuid,
    // Add database service here to save records
  }) async {
    // 1. Validate the bill belongs to this seller
    if (bill.sellerUuid != sellerUuid) {
      throw Exception('Security Error: This bill is not addressed to you.');
    }

    // 2. Extract Items
    final List<BillItem> items = bill.items;
    
    // 3. Loop through items and create local records
    // Pseudo-code:
    // for (var item in items) {
    //   await LocalDB.saveProduct(item);
    //   await LocalDB.createOrderRecord(bill, item);
    // }
    
    // 4. Create Import Record for "imports" JSON section
    final importRecord = ImportRecord(
      importId: DateTime.now().millisecondsSinceEpoch.toString(),
      billId: bill.billId,
      factoryUuid: bill.factoryUuid,
      factoryName: 'Factory ${bill.factoryUuid.substring(0, 8)}', // Replace with actual lookup
      importDate: DateTime.now(),
      billDate: bill.timestamp,
      totalAmount: bill.totalAmount,
      itemCount: bill.items.length,
      status: 'pending',
    );
    
    // 5. Save import record to local storage
    // await LocalDB.saveImportRecord(importRecord);
    
    print('Successfully imported ${items.length} items from ${bill.factoryUuid}');
  }
}
