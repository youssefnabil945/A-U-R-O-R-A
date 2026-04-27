# 🔄 Complete Supply Chain Flow Logic
## Factory ↔ Seller ↔ Customer Integration Guide

This document explains how data and products flow through the Aurora B2B2C platform, with special focus on the new **Offline Secure Sharing** feature.

---

## 📋 Table of Contents
1. [Overview](#overview)
2. [Flow 1: Factory to Seller (Restocking)](#flow-1-factory-to-seller-restocking)
3. [Flow 2: Seller to Customer (Retail Sales)](#flow-2-seller-to-customer-retail-sales)
4. [Security & Encryption Logic](#security--encryption-logic)
5. [Data Consistency & Sync](#data-consistency--sync)
6. [Error Handling & Validation](#error-handling--validation)

---

## 🎯 Overview

The Aurora platform connects three main actors:
- **Factory**: Manufactures products and sells wholesale
- **Seller**: Buys from factories and sells retail to customers
- **Customer**: End-user who buys from sellers

### Key Principles
1. **Connection Required**: Factories can only sell to Sellers they are connected with
2. **Stock Validation**: Sellers cannot sell what they don't have in inventory
3. **Offline-First**: All transactions work offline and sync when online
4. **Secure Sharing**: Files are encrypted with dual-UUID keys

---

## 🏭→👤 Flow 1: Factory to Seller (Restocking)

### Scenario A: Online Transaction (API-based)
```
Factory App → Creates Bill → Supabase API → Seller receives notification
```

**Steps:**
1. Factory selects connected Seller
2. Factory adds products and quantities
3. System validates:
   - ✅ Factory and Seller are connected
   - ✅ Products belong to this Factory
4. Bill is created in database
5. Seller gets real-time notification
6. Inventory updates automatically

### Scenario B: Offline Transaction (Secure Share) ⭐ NEW
```
Factory App → Create Bill → Encrypt File → Share (Quick Share/Bluetooth) 
                                                      ↓
Seller App ← Receive File ← Decrypt ← Validate ← Update Stock
```

**Detailed Steps:**

#### Step 1: Factory Creates Bill
- Selects Seller (via NFC/Bluetooth discovery or manual)
- Chooses products from catalog
- Sets quantities and prices
- System generates `WholesaleBill` object

#### Step 2: Encryption Process
```dart
// Simple explanation of the encryption:
// 1. Take Factory UUID + Seller UUID
// 2. Combine them to create a secret key
// 3. Lock the bill data with this key
// 4. Add a "label" on the outside with Factory ID (unencrypted)
// 5. Save as .aurora file
```

**File Structure:**
```
┌─────────────────────────────────────┐
│ HEADER (Plain Text)                 │
│ - factory_id: "uuid-123"            │
│ - timestamp: "2024-01-15..."        │
├─────────────────────────────────────┤
│ SEPARATOR: "||"                     │
├─────────────────────────────────────┤
│ PAYLOAD (Encrypted AES-256)         │
│ - Bill items                        │
│ - Prices                            │
│ - Quantities                        │
│ - Digital signature                 │
└─────────────────────────────────────┘
```

#### Step 3: Sharing
- Factory uses Android Quick Share / Bluetooth / WiFi Direct
- Sends `.aurora` file to Seller
- No internet required!

#### Step 4: Seller Receives & Processes
```dart
// What happens when Seller opens the file:
// 1. Read the header to see which Factory sent it
// 2. Combine MY UUID + FACTORY UUID to create the key
// 3. Try to unlock the payload
// 4. If key matches → Success! 
// 5. If key wrong → File is corrupted or not for me
```

**Validation Checks:**
- ✅ File format valid?
- ✅ Factory ID exists?
- ✅ Decryption successful?
- ✅ Bill addressed to THIS seller?
- ✅ Factory ID matches header?

#### Step 5: Update Inventory
- For each product in the bill:
  - Find product in local database
  - Add quantity to stock
  - Mark as "from import"
- Save import record for later sync

#### Step 6: Confirmation
- Seller sees: "Successfully imported X products"
- Import saved as "unsynced" 
- Will upload to cloud when online

---

## 👤→🛒 Flow 2: Seller to Customer (Retail Sales)

### Transaction Flow
```
Customer selects products → Seller validates stock → Process payment → Deduct stock → Update analytics
```

**Detailed Steps:**

#### Step 1: Stock Validation (CRITICAL)
Before any sale, system checks:
```dart
for each product in cart:
  - Does product exist? 
  - Is stock_quantity >= requested_quantity?
  
If NO → Block sale with error message
If YES → Continue
```

**Why this matters:**
- Prevents overselling
- Maintains accurate inventory
- Works offline using local cache

#### Step 2: Calculate Total
- Sum of (price × quantity) for all items
- Apply any discounts if applicable
- Final total locked before payment

#### Step 3: Create Sale Record
```dart
SaleRecord {
  id: unique_uuid,
  sellerId: current_seller,
  customerId: selected_customer,
  items: [...],
  totalAmount: 123.45,
  paymentMethod: cash/card,
  timestamp: now(),
  status: completed
}
```

#### Step 4: Deduct Stock
```dart
for each product sold:
  stock_quantity = stock_quantity - sold_quantity
  log reason: "sale"
  link to sale_id
```

#### Step 5: Update Customer Profile
- Add to purchase history
- Update total spent
- Track favorite products

#### Step 6: Update Analytics
- Increment daily sales counter
- Update top products list
- Recalculate revenue metrics

---

## 🔐 Security & Encryption Logic

### Dual-UUID Key System

**Concept in Simple Terms:**
Imagine two people (Factory and Seller) want to share a secret. They both have their own ID cards (UUIDs). To create a lock that only they can open:

1. **Key Generation:**
   ```
   Key = Factory_UUID + "_" + Seller_UUID
   Example: "f-123_s-456"
   ```

2. **Encryption (Factory side):**
   - Takes the bill data
   - Locks it with the combined key
   - Anyone can SEE who sent it (header)
   - Only the intended Seller can OPEN it (payload)

3. **Decryption (Seller side):**
   - Reads header to see Factory ID
   - Combines: My_UUID + Factory_UUID
   - Tries to unlock
   - If UUIDs match → Opens successfully
   - If wrong pair → Fails (security!)

### Why This is Secure

| Attack Scenario | Protection |
|----------------|------------|
| Hacker intercepts file | Can't decrypt without both UUIDs |
| Seller tries to open another seller's file | Wrong UUID combination fails |
| Fake factory sends file | Signature validation fails |
| Modified file | Checksum mismatch detected |

### Encryption Settings
- **Algorithm**: AES-256-GCM (military grade)
- **Key Derivation**: PBKDF2 with 100,000 iterations
- **IV**: Random 12-byte nonce per encryption
- **Authentication**: GCM tag prevents tampering

---

## 🔄 Data Consistency & Sync

### The Problem
- Users work offline most of the time
- Multiple transactions happen locally
- Need to sync to cloud when online
- Must avoid conflicts and duplicates

### The Solution: Queue-Based Sync

#### Import Queue
```dart
ImportRecord {
  id: uuid,
  billId: "bill-123",
  factoryId: "factory-456",
  importedAt: timestamp,
  synced: false  // ← Flag for sync
}
```

#### Sync Process (When Online)
```dart
1. Fetch all records where synced=false
2. For each import:
   - Send to API for verification
   - API checks with Factory's records
   - If valid → Mark synced=true
   - If invalid → Flag for review
3. For each sale:
   - Push to analytics API
   - Update global statistics
   - Mark synced=true
```

### Conflict Resolution
- **Last Write Wins**: Timestamp-based resolution
- **Manual Review**: For critical conflicts (e.g., negative stock)
- **Audit Log**: All changes tracked for debugging

---

## ⚠️ Error Handling & Validation

### Factory → Seller Errors

| Error | Cause | User Message |
|-------|-------|--------------|
| `NotConnectedException` | No connection request accepted | "You must be connected to this seller first" |
| `InvalidProductException` | Product doesn't belong to factory | "Cannot sell products you don't manufacture" |
| `DecryptionFailedException` | Wrong UUID or corrupted file | "File is corrupted or not intended for you" |
| `SignatureMismatchException` | File was tampered with | "Security alert: File has been modified" |

### Seller → Customer Errors

| Error | Cause | User Message |
|-------|-------|--------------|
| `InsufficientStockException` | Not enough inventory | "Only X items available in stock" |
| `ProductNotFoundException` | Product deleted/missing | "Product no longer exists in catalog" |
| `InvalidCustomerException` | Customer not found | "Customer profile missing" |
| `PaymentFailedException` | Payment processing error | "Payment could not be processed" |

### Validation Checklist

**Before Creating Wholesale Bill:**
- [ ] Factory verified
- [ ] Seller verified
- [ ] Connection exists
- [ ] Products owned by factory
- [ ] Quantities > 0
- [ ] Prices > 0

**Before Processing Import:**
- [ ] File format valid
- [ ] Header readable
- [ ] Factory ID exists
- [ ] Decryption successful
- [ ] Seller ID matches
- [ ] Signature valid

**Before Completing Retail Sale:**
- [ ] All products exist
- [ ] Stock sufficient for ALL items
- [ ] Customer exists
- [ ] Payment method valid
- [ ] Total calculated correctly

---

## 📊 Visual Flow Diagrams

### Complete Supply Chain
```
┌─────────────┐
│   FACTORY   │
│             │
│  • Makes    │
│  • Shares   │
│  • Tracks   │
└──────┬──────┘
       │ Wholesale (Online API or Encrypted File)
       ▼
┌─────────────┐
│    SELLER   │
│             │
│  • Imports  │
│  • Stocks   │
│  • Sells    │
└──────┬──────┘
       │ Retail (POS System)
       ▼
┌─────────────┐
│   CUSTOMER  │
│             │
│  • Buys     │
│  • Reviews  │
│  • Returns  │
└─────────────┘
```

### Offline Share Sequence
```
Factory                          Seller
   │                               │
   │─── Create Bill ───────────────│
   │                               │
   │─── Generate Key ──────────────│
   │    (F_UUID + S_UUID)          │
   │                               │
   │─── Encrypt Payload ───────────│
   │                               │
   │─── Add Plain Header ──────────│
   │    (Factory ID visible)       │
   │                               │
   │◄──── Quick Share File ───────►│
   │      (Bluetooth/WiFi)         │
   │                               │
   │                               │─── Read Header
   │                               │─── Generate Same Key
   │                               │─── Decrypt Payload
   │                               │─── Validate
   │                               │─── Update Stock ✓
   │                               │
```

---

## 🚀 Implementation Checklist

### For Developers
- [x] Create `SupplyChainFlowManager` class
- [x] Implement encryption/decryption helpers
- [x] Add validation logic for all flows
- [x] Create import/export record models
- [x] Build sync queue system
- [ ] Add unit tests for encryption
- [ ] Test offline scenarios
- [ ] Stress test with large bills (1000+ items)
- [ ] Implement retry logic for failed syncs

### For UI/UX
- [ ] Design file sharing screen
- [ ] Add progress indicators for import
- [ ] Show clear error messages
- [ ] Display sync status badge
- [ ] Create tutorial for first-time users

---

## 📝 Notes for Team

1. **Performance**: Encryption adds ~50ms per bill. Keep bills under 500 items for best UX.
2. **Storage**: Encrypted files average 2-5KB. Clean up old imports after 30 days.
3. **Compatibility**: Ensure both apps use same encryption version (check `ENCRYPTION_VERSION` constant).
4. **Testing**: Always test with different UUID combinations to verify security.

---

**Last Updated**: 2024
**Version**: 1.0.0
**Author**: Aurora Development Team
