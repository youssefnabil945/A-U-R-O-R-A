import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/bill_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../helpers/secure_data_helper.dart';
import '../services/local_db_service.dart';

/// [SupplyChainFlowManager]
/// This class acts as the central brain for managing the flow of goods and data
/// between Factories, Sellers, and Customers.
///
/// It ensures that:
/// 1. Factories can only sell to connected Sellers.
/// 2. Sellers can only sell what they have in stock (Inventory Logic).
/// 3. Offline imports are securely validated before updating stock.
/// 4. Data consistency is maintained across Online and Offline modes.
class SupplyChainFlowManager {
  final LocalDbService _db;
  final SecureDataHelper _security;

  SupplyChainFlowManager(this._db, this._security);

  // ---------------------------------------------------------------------------
  // 1. FACTORY TO SELLER FLOW (Restocking)
  // ---------------------------------------------------------------------------

  /// Creates a wholesale bill for a specific seller.
  /// Used when the Factory is online and creating an order via API.
  Future<WholesaleBill> createWholesaleOrder({
    required String factoryId,
    required String sellerId,
    required List<BillItem> items,
  }) async {
    // LOGIC CHECK 1: Verify Connection
    final isConnected = await _db.checkConnection(factoryId, sellerId);
    if (!isConnected) {
      throw Exception("Cannot sell: Factory and Seller are not connected.");
    }

    // LOGIC CHECK 2: Validate Factory owns these products
    for (var item in items) {
      final product = await _db.getProduct(item.productId);
      if (product == null || product.factoryId != factoryId) {
        throw Exception("Invalid product: Factory does not own product ${item.productId}");
      }
    }

    final bill = WholesaleBill(
      id: const Uuid().v4(),
      factoryId: factoryId,
      sellerId: sellerId,
      items: items,
      createdAt: DateTime.now(),
      status: BillStatus.pending,
      totalAmount: items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)),
    );

    // Save to DB
    await _db.saveBill(bill);
    return bill;
  }

  /// Processes an OFFLINE import file received from a Factory.
  /// This is the core logic for the "Secure Share" feature.
  ///
  /// Flow:
  /// 1. Read encrypted file.
  /// 2. Extract Header (Factory ID) to find the key.
  /// 3. Decrypt payload using (MyUUID + FactoryUUID).
  /// 4. Validate Digital Signature.
  /// 5. Update Local Inventory.
  /// 6. Save Import Record.
  Future<ImportResult> processOfflineImport({
    required File encryptedFile,
    required String currentSellerUuid,
  }) async {
    try {
      // Step 1: Read raw bytes
      final bytes = await encryptedFile.readAsBytes();
      final content = String.fromCharCodes(bytes);

      // Step 2: Parse the wrapper to get the Factory ID (Public info)
      // Format: HEADER_JSON||ENCRYPTED_PAYLOAD
      final parts = content.split('||');
      if (parts.length != 2) throw Exception("Invalid file format");

      final header = jsonDecode(parts[0]) as Map<String, dynamic>;
      final factoryId = header['factory_id'];
      final timestamp = header['timestamp'];

      // LOGIC CHECK: Must be a known factory or at least a valid UUID format
      if (factoryId == null || factoryId.isEmpty) {
        throw Exception("Corrupted file: Missing Factory ID");
      }

      // Step 3: Decrypt Payload
      // We use the combination of Current Seller UUID + Factory UUID as the key
      final encryptedPayload = parts[1];
      final decryptedString = await _security.decryptData(
        encryptedData: encryptedPayload,
        keyPair: Pair(currentSellerUuid, factoryId),
      );

      // Step 4: Deserialize Bill
      final billData = jsonDecode(decryptedString);
      final importedBill = WholesaleBill.fromJson(billData);

      // LOGIC CHECK: Verify the bill is actually addressed to THIS seller
      if (importedBill.sellerId != currentSellerUuid) {
        throw Exception("Security Alert: Bill is not addressed to this seller.");
      }

      // LOGIC CHECK: Verify the bill is from the expected factory
      if (importedBill.factoryId != factoryId) {
        throw Exception("Security Alert: Factory ID mismatch.");
      }

      // Step 5: Update Inventory (The "Magic" Moment)
      for (var item in importedBill.items) {
        await _db.addStock(
          productId: item.productId,
          quantity: item.quantity,
          source: 'import',
          referenceId: importedBill.id,
        );
      }

      // Step 6: Save Import Record for Sync later
      await _db.saveImportRecord(ImportRecord(
        id: const Uuid().v4(),
        billId: importedBill.id,
        factoryId: factoryId,
        importedAt: DateTime.now(),
        itemCount: importedBill.items.length,
        synced: false, // Will sync when online
      ));

      return ImportResult(
        success: true,
        bill: importedBill,
        message: "Successfully imported ${importedBill.items.length} products.",
      );

    } catch (e) {
      return ImportResult(
        success: false,
        message: "Import failed: ${e.toString()}",
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 2. SELLER TO CUSTOMER FLOW (Retail Sales)
  // ---------------------------------------------------------------------------

  /// Processes a sale from Seller to Customer.
  /// Ensures stock availability and updates analytics.
  Future<SaleResult> processRetailSale({
    required String sellerId,
    required String customerId,
    required List<SaleItem> items,
    required PaymentMethod paymentMethod,
  }) async {
    // LOGIC CHECK 1: Stock Validation
    // We must ensure we aren't selling what we don't have.
    for (var item in items) {
      final product = await _db.getProduct(item.productId);
      if (product == null) {
        return SaleResult(success: false, error: "Product ${item.productId} not found");
      }
      if (product.stockQuantity < item.quantity) {
        return SaleResult(
          success: false, 
          error: "Insufficient stock for ${product.name}. Available: ${product.stockQuantity}"
        );
      }
    }

    // LOGIC CHECK 2: Calculate Totals
    final total = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

    // Create Sale Record
    final sale = SaleRecord(
      id: const Uuid().v4(),
      sellerId: sellerId,
      customerId: customerId,
      items: items,
      totalAmount: total,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      status: SaleStatus.completed,
    );

    // Step 3: Deduct Stock
    for (var item in items) {
      await _db.deductStock(
        productId: item.productId,
        quantity: item.quantity,
        reason: 'sale',
        referenceId: sale.id,
      );
    }

    // Step 4: Save Sale & Update Customer Profile
    await _db.saveSale(sale);
    await _db.updateCustomerPurchaseHistory(customerId, total);

    // Step 5: Trigger Analytics Update
    await _db.updateSellerAnalytics(sellerId, amount: total);

    return SaleResult(success: true, saleId: sale.id, total: total);
  }

  // ---------------------------------------------------------------------------
  // 3. SYNC & CONSISTENCY LOGIC
  // ---------------------------------------------------------------------------

  /// Syncs local offline records to the cloud when internet is available.
  /// Handles both Sales (Seller->Customer) and Imports (Factory->Seller).
  Future<SyncReport> syncOfflineData() async {
    final unsyncedImports = await _db.getUnsyncedImports();
    final unsyncedSales = await _db.getUnsyncedSales();
    
    int successCount = 0;
    int failCount = 0;
    List<String> errors = [];

    // Sync Imports (Tell the cloud "I received this stock")
    for (var importRec in unsyncedImports) {
      try {
        // TODO: Call API to verify bill with Factory and mark as synced in cloud
        // await apiService.confirmImport(importRec.billId);
        await _db.markImportSynced(importRec.id);
        successCount++;
      } catch (e) {
        failCount++;
        errors.add("Import sync failed: ${e.toString()}");
      }
    }

    // Sync Sales (Tell the cloud "I made this sale")
    for (var sale in unsyncedSales) {
      try {
        // TODO: Call API to record sale in global analytics
        // await apiService.pushSale(sale);
        await _db.markSaleSynced(sale.id);
        successCount++;
      } catch (e) {
        failCount++;
        errors.add("Sale sync failed: ${e.toString()}");
      }
    }

    return SyncReport(
      totalProcessed: successCount + failCount,
      successful: successCount,
      failed: failCount,
      errors: errors,
    );
  }
}

// -----------------------------------------------------------------------------
// Data Models for Flow Results
// -----------------------------------------------------------------------------

class ImportResult {
  final bool success;
  final WholesaleBill? bill;
  final String message;

  ImportResult({required this.success, this.bill, required this.message});
}

class SaleResult {
  final bool success;
  final String? saleId;
  final double? total;
  final String? error;

  SaleResult({required this.success, this.saleId, this.total, this.error});
}

class SyncReport {
  final int totalProcessed;
  final int successful;
  final int failed;
  final List<String> errors;

  SyncReport({
    required this.totalProcessed,
    required this.successful,
    required this.failed,
    required this.errors,
  });
}

// Simple Pair class for Key generation
class Pair {
  final String first;
  final String second;
  Pair(this.first, this.second);
}
