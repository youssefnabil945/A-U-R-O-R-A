# 📄 Bill System Implementation Guide

## Overview
This guide covers the complete implementation of the Bill/Invoice system for Aurora, including:
- Multi-step bill creation wizard
- Advanced filtering and search
- PDF generation and printing
- Repository pattern with Supabase integration

---

## ✅ Files Created

### 1. Models
- `lib/models/bill/bill_model.dart` - Core bill data models (BillModel, BillRecipient, BillItem)
- `lib/core/enums/bill_type.dart` - Bill type enum (Standard, Proforma, Commercial)
- `lib/core/enums/bill_status.dart` - Bill status enum (Draft, Pending, Paid, Overdue, Cancelled)
- `lib/core/models/bill_filter_model.dart` - Filter model for searching and sorting bills

### 2. Data Layer
- `lib/data/repositories/bill_repository.dart` - Repository for bill CRUD operations with Supabase

### 3. Services
- `lib/services/bill_pdf_service.dart` - PDF generation, printing, and sharing service

### 4. UI Components
- `lib/pages/bills/widgets/app_bar_with_steps.dart` - Progress bar app bar for multi-step wizard
- `lib/pages/bills/` - Directory for bill-related pages (to be implemented)

### 5. Dependencies Added to pubspec.yaml
```yaml
equatable: ^2.0.5
pdf: ^3.10.7
printing: ^5.11.1
intl: ^0.19.0
```

---

## 🗄️ Database Schema Required

Add this table to your Supabase database:

```sql
-- Bills Table
CREATE TABLE IF NOT EXISTS bills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('standard', 'proforma', 'commercial')),
  recipient JSONB NOT NULL,
  items JSONB NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'paid', 'overdue', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  due_date TIMESTAMP WITH TIME ZONE,
  paid_at TIMESTAMP WITH TIME ZONE,
  pdf_url TEXT
);

-- Indexes for performance
CREATE INDEX idx_bills_seller_id ON bills(seller_id);
CREATE INDEX idx_bills_status ON bills(status);
CREATE INDEX idx_bills_created_at ON bills(created_at DESC);
CREATE INDEX idx_bills_type ON bills(type);

-- RLS Policies
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;

-- Sellers can only see their own bills
CREATE POLICY "Sellers can view own bills"
  ON bills FOR SELECT
  USING (auth.uid() = seller_id);

-- Sellers can insert their own bills
CREATE POLICY "Sellers can create bills"
  ON bills FOR INSERT
  WITH CHECK (auth.uid() = seller_id);

-- Sellers can update their own bills
CREATE POLICY "Sellers can update own bills"
  ON bills FOR UPDATE
  USING (auth.uid() = seller_id);

-- Sellers can delete their own bills
CREATE POLICY "Sellers can delete own bills"
  ON bills FOR DELETE
  USING (auth.uid() = seller_id);
```

---

## 📝 Next Steps to Complete Implementation

### Step 1: Run Database Migration
Execute the SQL schema above in your Supabase SQL Editor.

### Step 2: Create Bill Creation Wizard Pages
Create the following files in `lib/pages/bills/bill_steps/`:
- `bill_type_selection.dart` - Step 1: Choose bill type
- `recipient_details.dart` - Step 2: Enter recipient information
- `items_details.dart` - Step 3: Add bill items
- `summary_review.dart` - Step 4: Review and confirm

### Step 3: Create Main Bill Pages
- `lib/pages/bills/create_bill_page.dart` - Multi-step wizard container
- `lib/pages/bills/bills_list_page.dart` - List all bills with filters
- `lib/pages/bills/bill_details_page.dart` - View single bill details

### Step 4: Create Provider
- `lib/presentation/providers/bill_creation_provider.dart` - State management for bill creation
- `lib/presentation/providers/bill_list_provider.dart` - State management for bill list

### Step 5: Update Navigation
Add bill routes to your router and add menu items to the seller drawer.

### Step 6: Test
- Test bill creation flow
- Test PDF generation
- Test filtering and search
- Test on different screen sizes

---

## 🎯 Key Features Implemented

1. **Multi-Step Wizard**: 4-step process for creating bills
2. **Multiple Bill Types**: Standard, Proforma, Commercial invoices
3. **Advanced Filtering**: Search by recipient, filter by status/type/date range
4. **PDF Generation**: Professional invoice PDFs with company branding
5. **Print & Share**: Direct printing and PDF sharing capabilities
6. **Status Management**: Track bills from draft to paid
7. **Repository Pattern**: Clean separation of concerns
8. **RLS Security**: Row-level security in Supabase

---

## 📦 Usage Example

```dart
// Create a bill
final bill = BillModel(
  id: uuid.v4(),
  sellerId: currentSellerId,
  type: BillType.standard,
  recipient: BillRecipient(
    name: 'John Doe',
    email: 'john@example.com',
    phone: '+1234567890',
    address: '123 Main St, City, Country',
  ),
  items: [
    BillItem(
      id: uuid.v4(),
      productId: product.id,
      description: product.title,
      quantity: 2,
      price: 50.0,
    ),
  ],
  totalAmount: 100.0,
  currency: 'USD',
  createdAt: DateTime.now(),
);

// Save to database
final repository = BillRepository(supabaseService);
await repository.createBill(bill);

// Generate PDF
final pdfService = BillPdfService();
await pdfService.printBill(bill);
```

---

## 🔧 Troubleshooting

### PDF not generating?
- Ensure `pdf` and `printing` packages are installed
- Check that all bill fields are populated
- Verify file permissions on mobile devices

### Database errors?
- Confirm RLS policies are set correctly
- Check that seller_id matches authenticated user
- Verify JSONB structure for recipient and items

### Filter not working?
- Ensure bill_filter_model is properly imported
- Check date range logic (start <= end)
- Verify status/type filter values match enum names

---

## 📚 Additional Resources

- [PDF Package Documentation](https://pub.dev/packages/pdf)
- [Printing Package Documentation](https://pub.dev/packages/printing)
- [Supabase JSONB Guide](https://supabase.com/docs/guides/database/json-columns)

---

**Status**: Core infrastructure complete ✅  
**Next**: Implement UI pages and providers
