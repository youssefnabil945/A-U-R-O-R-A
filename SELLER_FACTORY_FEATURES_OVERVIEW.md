# Seller & Factory Features Overview

## 📋 Executive Summary

This document provides a comprehensive overview of the **Seller** and **Factory** features implemented in the Aurora application, including database schema, UI components, and testing coverage.

---

## 👤 SELLER FEATURES

### Database Schema (`sellers` table)

The `sellers` table supports both **seller** and **factory** account types with the following columns:

#### Core Fields
- `user_id` (UUID) - Primary key, references auth.users
- `email` (TEXT) - Seller's email address
- `full_name` (TEXT) - Complete name
- `phone` (TEXT) - Contact number
- `location` (TEXT) - Physical address
- `currency` (TEXT) - Default currency (e.g., 'EGP', 'USD')
- `account_type` (TEXT) - Either 'seller' or 'factory'

#### Verification & Status
- `is_verified` (BOOLEAN) - Account verification status
- `is_factory` (BOOLEAN) - Flag to identify factory accounts
- `verified_at` (TIMESTAMPTZ) - Verification timestamp

#### Factory-Specific Fields
- `factory_license_url` (TEXT) - License document URL
- `min_order_quantity` (INTEGER) - Minimum order quantity
- `wholesale_discount` (NUMERIC) - Wholesale discount percentage
- `accepts_returns` (BOOLEAN) - Return policy flag
- `production_capacity` (TEXT) - Production capacity description

#### Location Coordinates
- `latitude` (DECIMAL) - GPS latitude
- `longitude` (DECIMAL) - GPS longitude

#### Metadata
- `chat_room_id` (UUID) - Chat room identifier
- `created_at`, `updated_at` (TIMESTAMPTZ) - Timestamps

### UI Components

#### 1. Seller Profile Page
**File:** `/workspace/lib/pages/seller/sellerProfile.dart`

**Features:**
- ✅ Displays seller profile information in organized sections
- ✅ Account Information (UUID, Full Name, Account Type)
- ✅ Contact Details (Email, Phone)
- ✅ Location & Currency information
- ✅ Verification Status badge
- ✅ Pull-to-refresh functionality
- ✅ Manual refresh button (fetches from Supabase)
- ✅ Error handling with retry option
- ✅ Responsive layout with split cards
- ✅ Dark/Light theme support

**Key Methods:**
- `_loadSellerData()` - Loads data from Supabase or local cache
- `_fetchSellerFromSupabaseTable()` - Force refresh from database
- `_buildProfileHeader()` - Gradient header with avatar
- `_buildSplitInfoCard()` - Two-column information layout
- `_buildContactCard()` - Contact details card
- `_buildLocationCard()` - Location and currency card
- `_buildVerificationCard()` - Verification status display

### Backend Services

#### SellerDB Service
**File:** `/workspace/lib/backend/sellerdb.dart`

**Capabilities:**
- Local SQLite caching of seller profiles
- Chat room ID management
- CRUD operations for seller data
- Support for both seller and factory account types

---

## 🏭 FACTORY FEATURES

### Database Schema

#### Factory Support Migration
**File:** `/workspace/supabase/migrations/012_add_factory_support_to_sellers.sql`

This migration adds factory-specific functionality:

1. **Factory Columns in Sellers Table**
   - `is_factory` flag
   - `factory_license_url`
   - `min_order_quantity`
   - `wholesale_discount`
   - `accepts_returns`
   - `production_capacity`

2. **Factory Connections Table**
```sql
CREATE TABLE factory_connections (
  id UUID PRIMARY KEY,
  factory_id UUID REFERENCES sellers(user_id),
  seller_id UUID REFERENCES sellers(user_id),
  status TEXT CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
  requested_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  notes TEXT,
  UNIQUE(factory_id, seller_id)
);
```

3. **Factory Ratings Table**
```sql
CREATE TABLE factory_ratings (
  id UUID PRIMARY KEY,
  factory_id UUID REFERENCES sellers(user_id),
  seller_id UUID REFERENCES sellers(user_id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  delivery_rating INTEGER,
  quality_rating INTEGER,
  communication_rating INTEGER,
  UNIQUE(factory_id, seller_id)
);
```

### Data Models

#### AuroraFactory Model
**File:** `/workspace/lib/models/aurora_factory.dart`

**Properties:**
- `id`, `uuid` - Unique identifiers
- `name`, `ownerName`, `email`, `phone` - Contact info
- `location`, `latitude`, `longitude` - Location data
- `specialization` - What the factory produces
- `status` - 'active', 'inactive', 'pending'
- `productCategories` - List of product categories
- `totalDeals`, `totalVolume` - Business metrics
- `rating` - Average rating (1-5)
- `analysis` - KPI analysis map

**Factory Deal Model:**
- `FactoryDeal` - Represents deals between sellers and factories
- `DealItem` - Individual items in a deal
- Tracks payment status, deal status, and metadata

### UI Components

#### Factories Page
**File:** `/workspace/lib/pages/factory/factories_page.dart`

**Features:**
- ✅ Grid/List view toggle
- ✅ Search functionality (by name, owner, specialization)
- ✅ Sorting options (Name, Deals, Volume)
- ✅ Ascending/Descending sort order
- ✅ Factory cards with status badges
- ✅ QR code sharing for each factory
- ✅ Statistics display (deals, volume)
- ✅ Add new factory dialog
- ✅ Factory detail navigation
- ✅ Pull-to-refresh

**View Components:**
- `_FactoryGridTile` - 2-column grid layout
- `_FactoryListTile` - List view layout
- `_StatChip` - Metric display chips
- `_AddFactoryDialog` - Factory creation form

### Backend Services

#### FactoriesDB Service
**File:** `/workspace/lib/services/factories_db.dart`

**Capabilities:**
- Local storage of factory data
- Factory CRUD operations
- Deal tracking and analytics
- Connection request management

#### Factory Materials DB
**File:** `/workspace/lib/services/factory_materials_db.dart`

**Purpose:**
- Track raw materials used by factories
- Material inventory management

---

## 🔐 ROW LEVEL SECURITY (RLS)

### Sellers Table Policies

1. **Users can view own profile**
   ```sql
   USING (auth.uid() = user_id)
   ```

2. **Users can update own profile**
   ```sql
   USING (auth.uid() = user_id)
   ```

3. **Users can insert own profile**
   ```sql
   WITH CHECK (auth.uid() = user_id)
   ```

4. **Anyone can view verified sellers and factories**
   ```sql
   USING (is_verified = TRUE OR is_factory = TRUE)
   ```

### Factory Connections Policies

1. **Users can view own connections**
   ```sql
   USING (seller_id = auth.uid() OR factory_id = auth.uid())
   ```

2. **Users can create connection requests**
   ```sql
   WITH CHECK (seller_id = auth.uid())
   ```

3. **Factories can update own connections**
   ```sql
   USING (factory_id = auth.uid())
   ```

### Factory Ratings Policies

1. **Anyone can view ratings**
   ```sql
   USING (true)
   ```

2. **Sellers can create ratings**
   ```sql
   WITH CHECK (seller_id = auth.uid())
   ```

---

## 🎨 THEME SUPPORT

### Available Themes

The app supports **5 theme presets** with proper light/dark mode support:

#### Light Theme
1. **VS Code Light+** (Default Light)
   - Primary: `#007ACC` (VS Code Blue)
   - Secondary: `#2B88D8`
   - Accent: `#0E639C`
   - Surface: White
   - Background: `#F5F5F7`

#### Dark Themes
1. **VS Code Dark+** (Default Dark)
   - Primary: `#569CD6`
   - Secondary: `#4EC9B0`
   - Accent: `#D4D4D4`
   - Surface: `#1E1E1E`
   - Background: `#111111`

2. **Dracula**
   - Primary: `#BD93F9` (Purple)
   - Secondary: `#50FA7B` (Green)
   - Accent: `#FF79C6` (Pink)

3. **Monokai**
   - Primary: `#66D9EF` (Cyan)
   - Secondary: `#A6E22E` (Yellow-Green)
   - Accent: `#F92672` (Pink)

4. **Solarized Dark**
   - Primary: `#268BD2` (Blue)
   - Secondary: `#2AA198` (Teal)
   - Accent: `#B58900` (Amber)

### Theme Testing

Two comprehensive test suites have been added:

1. **Light Theme Tests** (`/workspace/test/unit/theme/light_theme_test.dart`)
   - 18 test cases covering:
     - Brightness verification
     - Color scheme validation
     - Component theming (buttons, cards, inputs, etc.)
     - Text contrast and accessibility
     - Icon, chip, divider styling
     - Snackbar and dropdown menus

2. **Dark Theme Tests** (`/workspace/test/unit/theme/dark_theme_test.dart`)
   - 20 test cases covering:
     - All light theme tests adapted for dark mode
     - Additional luminance validation
     - Multiple dark theme palette verification
     - Contrast ratio checks

---

## 🔄 MULTI-ROLE SYSTEM

### Account Types

The system supports multiple account types through a unified `sellers` table:

| Account Type | Description | Key Features |
|-------------|-------------|--------------|
| `seller` | Retail sellers | Product listing, customer management, sales tracking |
| `factory` | Manufacturers | Wholesale pricing, production capacity, B2B connections |

### Auto-Profile Creation

When a user signs up with `account_type: 'seller'` or `account_type: 'factory'`:
1. User is created in `auth.users`
2. Trigger `handle_new_user()` automatically creates a record in `sellers` table
3. For factories, `is_factory` is set to `TRUE`
4. Default values are applied based on account type

---

## 📊 TESTING COVERAGE

### Current Test Files

| File | Purpose | Status |
|------|---------|--------|
| `test/unit/theme/light_theme_test.dart` | Light theme validation | ✅ Created |
| `test/unit/theme/dark_theme_test.dart` | Dark theme validation | ✅ Created |
| `test/unit/services/theme_provider_test.dart` | Theme state management | Existing |
| `test/unit/models/aurora_product_test.dart` | Product model tests | Existing |
| `test/unit/backend/sellerdb_test.dart` | Seller database tests | Existing |

### Running Theme Tests

```bash
# Run all theme tests
flutter test test/unit/theme/

# Run specific test file
flutter test test/unit/theme/light_theme_test.dart
flutter test test/unit/theme/dark_theme_test.dart
```

---

## 🚀 NEXT STEPS / RECOMMENDATIONS

### Immediate Actions

1. **Run Theme Tests**
   ```bash
   flutter test test/unit/theme/
   ```

2. **Verify RLS Policies**
   - Test that sellers can only view/edit their own profiles
   - Verify factories are visible to all authenticated users
   - Test factory connection request flow

3. **Test Factory Features**
   - Create factory account
   - Add factory profile
   - Test seller-factory connection requests
   - Verify QR code sharing works

### Future Enhancements

1. **Factory Dashboard**
   - Production capacity visualization
   - Order management interface
   - Wholesale pricing tiers

2. **Seller-Factory Matching**
   - Recommendation algorithm
   - Geographic proximity search
   - Specialization-based filtering

3. **Enhanced Analytics**
   - Deal trend analysis
   - Performance metrics dashboard
   - Rating and review system

4. **Mobile Optimizations**
   - Offline mode for factory catalogs
   - NFC-based factory discovery
   - Quick Share integration

---

## 📁 FILE REFERENCE

### Key Files

#### Frontend
- `/lib/pages/seller/sellerProfile.dart` - Seller profile UI
- `/lib/pages/factory/factories_page.dart` - Factory listing UI
- `/lib/models/aurora_factory.dart` - Factory data models
- `/lib/theme/themeprovider.dart` - Theme configuration

#### Backend
- `/lib/backend/sellerdb.dart` - Seller database service
- `/lib/services/factories_db.dart` - Factory database service
- `/lib/services/factory_materials_db.dart` - Materials tracking

#### Database
- `/supabase/migrations/012_add_factory_support_to_sellers.sql` - Factory migration
- `/supabase/migrations/20260305000000_create_factory_discovery_system.sql` - Discovery system
- `/supabase/sellers_table.sql` - Sellers table schema

#### Tests
- `/test/unit/theme/light_theme_test.dart` - Light theme tests (NEW ✨)
- `/test/unit/theme/dark_theme_test.dart` - Dark theme tests (NEW ✨)

---

## 📞 SUPPORT

For questions or issues related to Seller/Factory features:
- Check the migration files for database schema details
- Review the model files for data structure
- Run the test suites to verify functionality
- Consult the RLS policies for security rules

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-17  
**Author:** Aurora Development Team
