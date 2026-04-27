# 📦 Offline Factory-to-Seller Sharing Feature

## 🎯 Overview
This feature allows Factories to sell products to Sellers **offline** using built-in sharing (Quick Share, Bluetooth, Nearby Share) without needing an active internet connection at the moment of transfer.

---

## 🔄 The Complete Flow

### **Step 1: Factory Side - Creating the Bill**
1. **Select Seller**: 
   - Factory opens "Sell Products" screen
   - Uses NFC/Bluetooth discovery OR selects from existing connections
   - App retrieves `sellerUuid`

2. **Build Order**:
   - Factory browses their product catalog
   - Selects products + quantities
   - Chooses payment method (Cash, Card, Credit)
   - Adds optional notes

3. **Generate & Encrypt**:
   - App creates a Bill JSON object
   - **Encryption Key** = SHA256(FactoryUUID + SellerUUID)
   - Bill is locked with AES-256 encryption
   - Saved as `.aurora` file (CSV-like format)

4. **Share**:
   - Triggers system share sheet
   - Factory sends via Quick Share / Nearby Share / Bluetooth
   - File transfers directly device-to-device

---

### **Step 2: Seller Side - Receiving the Bill**
1. **Receive File**:
   - Seller's phone receives the `.aurora` file
   - File appears in Downloads or notification tray

2. **Open in Aurora App**:
   - Seller taps file → Opens Aurora App
   - Or: Seller opens app → "Import Bill" → Selects file

3. **Decrypt & Validate**:
   - App reads file header to get `factoryUuid`
   - **Decryption Key** = SHA256(SellerUUID + FactoryUUID)
   - If keys match → Data unlocks ✅
   - If wrong user → Decryption fails 🔒

4. **Process Import**:
   - Validates bill is addressed to this seller
   - Creates local product records
   - Creates order record in "Imports" section
   - Updates inventory & analytics

---

## 🔐 Security Model

### **How Encryption Works**
```
Factory UUID: 550e8400-e29b-41d4-a716-446655440000
Seller UUID:  6ba7b810-9dad-11d1-80b4-00c04fd430c8

Combined & Sorted: 
  550e8400... : 6ba7b810...

SHA-256 Hash → 32-byte Key
  (Same result every time for this pair)

AES-256 Encryption:
  Plain Bill → [Key] → Gibberish → Base64 String
```

### **File Format (.aurora)**
```csv
AURORA_V1,<FACTORY_UUID>,<ENCRYPTED_PAYLOAD>
```

**Example:**
```
AURORA_V1,550e8400-e29b-41d4-a716-446655440000,SGVsbG8gV29ybCE=...
```

- **Header**: Plain text version identifier
- **Factory UUID**: Plain text (needed to find the right key)
- **Payload**: Encrypted bill data (unreadable without both UUIDs)

---

## 📁 File Structure

```
lib/
├── utils/
│   └── secure_data_helper.dart      # Encryption/Decryption logic
├── services/
│   └── offline_bill_manager.dart    # Share & Import flow
├── models/
│   └── bill_model.dart              # Bill, BillItem, ImportRecord models
└── screens/
    ├── factory/
    │   └── offline_sell_screen.dart # UI for creating bills (TODO)
    └── seller/
        └── import_bill_screen.dart  # UI for importing bills (TODO)
```

---

## 🛠️ Required Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  encrypt: ^5.0.1          # AES encryption
  crypto: ^3.0.3           # SHA-256 hashing
  share_plus: ^7.2.1       # System share sheet
  file_picker: ^6.1.1      # File selection
  path_provider: ^2.1.1    # Temp file storage
  permission_handler: ^11.1.0 # Bluetooth/NFC permissions
```

---

## 📱 User Interface Requirements

### **Factory Screen: "Offline Sell"**
- [ ] List of connected sellers (or NFC scan button)
- [ ] Product grid with quantity selectors
- [ ] Cart summary (total items, total price)
- [ ] Payment method dropdown
- [ ] "Generate & Share Bill" button

### **Seller Screen: "Imports"**
- [ ] "Import Bill" button (opens file picker)
- [ ] List of pending imported bills
- [ ] Bill details view (items, totals, factory info)
- [ ] "Accept & Add to Inventory" button
- [ ] Transaction history

---

## ⚡ Fast Implementation Strategy

### **Phase 1: Core Logic (Done ✅)**
- [x] `secure_data_helper.dart` - Encryption engine with simple comments
- [x] `offline_bill_manager.dart` - Share/Import service
- [x] `bill_model.dart` - Bill, BillItem, ImportRecord models
- [x] `pubspec.yaml` - Added file_picker dependency

### **Phase 2: UI Integration (Next Steps)**
1. Create `offline_sell_screen.dart` for Factory
   - Product selection grid
   - Seller selector (NFC/Bluetooth or from list)
   - Cart summary
   - "Share Bill" button
2. Create `import_bill_screen.dart` for Seller
   - "Import Bill" button
   - Pending imports list
   - Bill detail view
   - "Accept & Process" button
3. Add "Imports" section to Seller dashboard JSON storage

### **Phase 3: Testing**
1. Test encryption/decryption with sample UUIDs
2. Test file sharing between two physical devices
3. Test error cases (wrong user, corrupted file)
4. Test large bills (100+ items)

---

## 🚨 Important Notes

1. **Internet Not Required**: The actual file transfer works offline (Bluetooth/WiFi Direct)
2. **Initial Connection**: Factory & Seller must have exchanged UUIDs beforehand (via online connection request)
3. **File Size**: Keep bills small (<1MB) for fast Bluetooth transfer
4. **Security**: Never share UUIDs publicly; they are the encryption keys
5. **Backup**: Encrypted files cannot be recovered if UUIDs are lost

---

## 📝 Sample Code Usage

### **Factory: Create & Share Bill**
```dart
// 1. Create bill items from selected products
final List<BillItem> items = [
  BillItem.calculate(
    productId: 'prod_123',
    productName: 'Wireless Headphones',
    sku: 'WH-001',
    quantity: 50,
    unitPrice: 10.00,
  ),
  BillItem.calculate(
    productId: 'prod_456',
    productName: 'USB-C Cable',
    sku: 'UC-002',
    quantity: 100,
    unitPrice: 5.00,
  ),
];

// 2. Create the bill
final bill = OfflineBillManager.createBill(
  factoryUuid: currentFactory.id,
  sellerUuid: selectedSeller.id,
  items: items,
  paymentMethod: 'CASH',
  notes: 'Bulk order discount applied',
);

// 3. Share via Quick Share / Bluetooth
await OfflineBillManager.shareBillWithSeller(
  bill: bill,
  factoryUuid: currentFactory.id,
  sellerUuid: selectedSeller.id,
);
// → Opens system share sheet automatically
```

### **Seller: Import & Process Bill**
```dart
try {
  // 1. Open file picker and decrypt
  final BillModel? bill = await OfflineBillManager.importBillFromFile(
    sellerUuid: currentSeller.id,
  );

  if (bill != null) {
    // 2. Show preview to user
    showDialog(
      builder: (_) => BillPreviewDialog(bill: bill),
    );

    // 3. After user confirms, process the import
    await OfflineBillManager.processImportedBill(
      bill: bill,
      sellerUuid: currentSeller.id,
    );

    // 4. Success! Items added to inventory
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${bill.items.length} products!')),
    );
  }
} catch (e) {
  // Handle errors (wrong user, corrupted file, etc.)
  showErrorDialog('Failed to import: ${e.toString()}');
}
```

### **Seller: View Imports History**
```dart
// Access from local storage (SharedPreferences/Hive)
final List<ImportRecord> imports = await LocalDB.getImportRecords();

for (var import in imports) {
  print('Bill from: ${import.factoryName}');
  print('Amount: \$${import.totalAmount}');
  print('Status: ${import.status}');
}
```

---

## ✅ Checklist for Completion

- [ ] Add dependencies to `pubspec.yaml`
- [ ] Build Factory UI for product selection
- [ ] Build Seller UI for file import
- [ ] Integrate with local database (Hive/SQLite)
- [ ] Add error handling & user feedback
- [ ] Test on Android (Quick Share) & iOS (AirDrop)
- [ ] Add NFC discovery (optional enhancement)
- [ ] Add batch processing for large bills
