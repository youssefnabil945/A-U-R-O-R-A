# Aurora E-Commerce Platform - Complete Documentation

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Setup & Installation](#setup--installation)
4. [Configuration](#configuration)
5. [Database Schema](#database-schema)
6. [Core Features](#core-features)
7. [API Reference](#api-reference)
8. [File Structure](#file-structure)

---

## Project Overview

**Aurora** is a multi-vendor e-commerce marketplace platform built with Flutter and Supabase.

### Key Features
- User Authentication (Email/Password, Google Sign-In)
- Seller Management & Profiles
- Product Management with Categories/Subcategories
- Real-time Chat with Deal Negotiation
- Commission-based Deal System
- Biometric Authentication
- Theme Customization (Light/Dark/System)
- Multi-language Support (English/Arabic)
- Offline-first Architecture with SQLite
- Push Notifications via Firebase
- Location Services
- Image Upload & Caching
- QR Code Generation for Products

### Tech Stack
- **Frontend**: Flutter 3.10+
- **Backend**: Supabase (PostgreSQL + Realtime)
- **Local Database**: SQLite
- **State Management**: Provider
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage
- **Notifications**: Firebase Cloud Messaging

---

## Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── config/                   # Configuration files
│   ├── supabase_config.dart  # Supabase credentials & settings
│   └── performance_config.dart
├── models/                   # Data models
│   ├── aurora_product.dart   # Enhanced product model
│   ├── product.dart          # Amazon-style product model
│   ├── seller.dart           # Seller model
│   ├── aurora_customer.dart
│   ├── aurora_factory.dart
│   ├── bill_model.dart
│   └── chat/
│       └── deal_proposal.dart
├── services/                 # Business logic & providers
│   ├── auth_provider.dart    # Authentication management
│   ├── product_provider.dart # Product operations
│   ├── supabase.dart         # Supabase client wrapper
│   ├── queue_service.dart    # Offline queue management
│   ├── deal_chat_service.dart
│   └── ...
├── backend/                  # Local database managers
│   ├── sellerdb.dart         # Sellers SQLite DB
│   └── products_db.dart      # Products SQLite DB
├── pages/                    # UI screens
│   ├── singup/               # Login, Signup, Home
│   ├── product/              # Product forms & listings
│   ├── customer/             # Customer management
│   ├── orders/               # Orders screen
│   ├── factory/              # Factories page
│   ├── setting/              # Settings
│   └── user/                 # User-specific pages
├── widgets/                  # Reusable UI components
│   ├── drawer.dart
│   ├── product_image_upload.dart
│   ├── deal_proposal_card.dart
│   └── ...
├── theme/                    # Theme configuration
│   └── themeprovider.dart
├── l10n/                     # Localization files
│   ├── app_localizations.dart
│   ├── app_localizations_en.dart
│   └── app_localizations_ar.dart
└── utils/                    # Helper utilities
    ├── json_helpers.dart
    ├── connectivity_helper.dart
    └── secure_data_helper.dart
```

### State Management
The app uses **Provider** for state management with the following providers:
- `AuthProvider` - User authentication state
- `ProductProvider` - Product data & operations
- `ThemeProvider` - Theme preferences
- `UserPreferencesService` - User settings (language, currency)
- `PresenceService` - Online/offline status
- `SellerDB` - Local seller data
- `ProductsDB` - Local product data
- `FactoriesDB` - Local factory data

---

## Setup & Installation

### Prerequisites
- Flutter SDK 3.10+
- Dart 3.10+
- Supabase account
- Firebase project (for push notifications)

### Installation Steps

1. **Clone the repository**
```bash
git clone <repository-url>
cd aurora
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Supabase credentials**

Create a `.env` file in the project root:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

4. **Run the app**
```bash
flutter run --dart-define-from-file=.env
```

Or use command-line arguments:
```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

---

## Configuration

### Supabase Configuration (`lib/config/supabase_config.dart`)

```dart
class SupabaseConfig {
  // Credentials (set via --dart-define or .env file)
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  
  // Cache configuration
  static const Duration cacheDuration = Duration(minutes: 5);
  static const Duration analyticsCacheDuration = Duration(minutes: 15);
  
  // Edge Functions
  static const String functionProcessSignup = 'process-signup';
  static const String functionProcessLogin = 'process-login';
  static const String functionCreateProduct = 'create-product';
  static const String functionUpdateProduct = 'update-product';
  static const String functionDeleteProduct = 'delete-product';
  static const String functionListProducts = 'list-products';
  static const String functionSearchProducts = 'search-products';
  static const String functionCreateOrder = 'create-order';
  static const String functionGetOrCreateConversation = 'get-or-create-conversation';
  
  // Database Tables
  static const String tableSellers = 'sellers';
  static const String tableProducts = 'products';
  static const String tableOrders = 'orders';
  static const String tableMessages = 'messages';
  static const String tableConversations = 'conversations';
}
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_ANON_KEY` | Supabase anonymous/public key | Yes |

---

## Database Schema

### Supabase Tables

#### 1. Sellers Table
```sql
CREATE TABLE sellers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  firstname TEXT,
  secondname TEXT,
  thirdname TEXT,
  forthname TEXT,
  phone TEXT NOT NULL,
  location TEXT,
  currency TEXT DEFAULT 'USD',
  account_type TEXT DEFAULT 'seller',
  store_name TEXT,
  store_description TEXT,
  logo_url TEXT,
  banner_url TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  last_login TIMESTAMP WITH TIME ZONE,
  rating DECIMAL DEFAULT 0.0,
  total_sales INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);
```

#### 2. Products Table
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asin TEXT UNIQUE,
  sku TEXT,
  seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  marketplace_id TEXT,
  product_type TEXT,
  status TEXT DEFAULT 'draft',
  
  -- Product Identifiers (JSONB)
  identifiers JSONB,
  
  -- Product Content
  title TEXT,
  description TEXT,
  bullet_points JSONB,
  brand TEXT,
  manufacturer TEXT,
  language TEXT DEFAULT 'en_US',
  
  -- Category & Subcategory
  category TEXT,
  subcategory TEXT,
  brand_id UUID REFERENCES brands(id),
  is_local_brand BOOLEAN DEFAULT FALSE,
  
  -- Product Pricing
  currency TEXT DEFAULT 'USD',
  list_price DECIMAL(10,2),
  selling_price DECIMAL(10,2),
  business_price DECIMAL(10,2),
  tax_code TEXT,
  
  -- Product Inventory
  quantity INTEGER DEFAULT 0,
  fulfillment_channel TEXT,
  availability_status TEXT,
  lead_time_to_ship TEXT,
  
  -- Product Images (JSONB)
  images JSONB,
  
  -- Product Attributes (JSONB)
  attributes JSONB DEFAULT '{}',
  
  -- Color hex code (for Fashion & Apparel)
  color_hex TEXT,
  
  -- Product Variations (JSONB)
  variations JSONB,
  
  -- Product Compliance (JSONB)
  compliance JSONB,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  version TEXT,
  
  -- Soft Delete
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE
);
```

#### 3. Categories Table
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  icon_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4. Subcategories Table
```sql
CREATE TABLE subcategories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  attribute_schema JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 5. Brands Table
```sql
CREATE TABLE brands (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  logo_url TEXT,
  website_url TEXT,
  country TEXT,
  category TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 6. Customers Table
```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  age_range TEXT,
  email TEXT,
  notes TEXT,
  total_orders INTEGER DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 7. Messages Table (Chat)
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id),
  sender_id UUID REFERENCES auth.users(id),
  message_type TEXT DEFAULT 'text',
  content TEXT,
  image_url TEXT,
  file_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 8. Conversations Table (Chat)
```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  participant_1_id UUID REFERENCES auth.users(id),
  participant_2_id UUID REFERENCES auth.users(id),
  product_id UUID REFERENCES products(id),
  last_message TEXT,
  last_message_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Local SQLite Tables

#### Sellers DB (`sellers.db`)
```sql
CREATE TABLE sellers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL UNIQUE,
  firstname TEXT NOT NULL,
  secondname TEXT NOT NULL,
  thirdname TEXT NOT NULL,
  fourthname TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  location TEXT NOT NULL,
  phone TEXT NOT NULL,
  currency TEXT,
  account_type TEXT DEFAULT 'seller',
  is_verified INTEGER DEFAULT 0,
  latitude REAL,
  longitude REAL,
  chat_room_id TEXT,
  created_at TEXT,
  updated_at TEXT
);
```

#### Products DB (`aurora_products.db`)
```sql
CREATE TABLE products (
  asin TEXT PRIMARY KEY,
  sku TEXT,
  seller_id TEXT,
  marketplace_id TEXT,
  product_type TEXT,
  status TEXT,
  title TEXT,
  description TEXT,
  bullet_points TEXT,
  brand TEXT,
  manufacturer TEXT,
  language TEXT,
  currency TEXT,
  list_price REAL,
  selling_price REAL,
  business_price REAL,
  tax_code TEXT,
  quantity INTEGER,
  fulfillment_channel TEXT,
  availability_status TEXT,
  lead_time_to_ship TEXT,
  images TEXT,
  variations TEXT,
  compliance TEXT,
  allow_chat INTEGER DEFAULT 1,
  qr_data TEXT,
  brand_id TEXT,
  is_local_brand INTEGER DEFAULT 0,
  color_hex TEXT,
  category TEXT,
  subcategory TEXT,
  attributes TEXT,
  created_at TEXT,
  updated_at TEXT,
  version TEXT,
  is_synced INTEGER DEFAULT 0,
  synced_at TEXT,
  local_created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  local_updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

---

## Core Features

### 1. Authentication

**Location**: `lib/services/auth_provider.dart`

```dart
// Login
final result = await authProvider.login(
  email: 'user@example.com',
  password: 'password123',
);

// Signup
final result = await authProvider.signup(
  email: 'user@example.com',
  password: 'password123',
  fullName: 'John Doe',
  phone: '+1234567890',
  accountType: AccountType.seller,
);

// Google Sign-In
final result = await authProvider.signInWithGoogle();

// Logout
await authProvider.logout();

// Check session
bool isLoggedIn = authProvider.isLoggedIn;
User? user = authProvider.user;
```

### 2. Product Management

**Location**: `lib/services/product_provider.dart`

```dart
// Create product
final product = AuroraProduct(
  title: 'Sample Product',
  description: 'Product description',
  sellingPrice: 99.99,
  currency: 'USD',
  quantity: 100,
  category: 'Electronics',
  subcategory: 'Smartphones',
  brand: 'Samsung',
  images: [ProductImage(url: 'https://...')],
);

final result = await productProvider.createProduct(product);

// Update product
product.title = 'Updated Title';
final result = await productProvider.updateProduct(product);

// Get all products
final products = await productProvider.getAllProducts();

// Search products
final results = await productProvider.searchProducts(query: 'phone');

// Delete product
await productProvider.deleteProduct(asin: 'B01234567');
```

### 3. Chat System

**Location**: `lib/services/deal_chat_service.dart`

```dart
// Get or create conversation
final conversation = await dealChatService.getOrCreateConversation(
  participantId: 'user-uuid',
  productId: 'product-asin',
);

// Send message
await dealChatService.sendMessage(
  conversationId: 'conversation-uuid',
  message: 'Hello!',
  messageType: 'text',
);

// Send image
await dealChatService.sendImageMessage(
  conversationId: 'conversation-uuid',
  imageFile: imageFile,
);

// Get conversation messages
final messages = await dealChatService.getMessages(conversationId);

// Send deal proposal
await dealChatService.sendDealProposal(
  conversationId: 'conversation-uuid',
  commissionRate: 0.15,
  message: 'I propose 15% commission',
);
```

### 4. Offline Queue Service

**Location**: `lib/services/queue_service.dart`

```dart
// Add operation to queue
await queueService.addToQueue(QueueItem(
  type: QueueItemType.createProduct,
  data: product.toJson(),
  timestamp: DateTime.now(),
));

// Process queue when online
await queueService.processQueue();

// Get pending items count
int pendingCount = queueService.pendingCount;
```

### 5. Image Upload

**Location**: `lib/services/image_upload_service.dart`

```dart
// Upload single image
final imageUrl = await imageUploadService.uploadImage(
  imageFile: imageFile,
  folder: 'products',
);

// Upload multiple images
final imageUrls = await imageUploadService.uploadMultipleImages(
  imageFiles: [file1, file2, file3],
  folder: 'products',
);

// Get image URL
final url = await imageUploadService.getImageUrl(path: 'products/image.jpg');

// Delete image
await imageUploadService.deleteImage(path: 'products/image.jpg');
```

### 6. Location Services

**Location**: `lib/services/permissions.dart`, `lib/screens/chat/nearby_users_screen.dart`

```dart
// Request permissions
await AppPermissions.requestPermissions();

// Get current location
final location = await Geolocator.getCurrentPosition();

// Get nearby users
final nearbyUsers = await nearbyChatService.getNearbyUsers(
  latitude: location.latitude,
  longitude: location.longitude,
  radiusKm: 5.0,
);
```

---

## API Reference

### Models

#### AuroraProduct
```dart
class AuroraProduct {
  // Core fields
  String? asin;
  String? sku;
  String? sellerId;
  String? marketplaceId;
  String? productType;
  String? status;
  
  // Content
  String? title;
  String? description;
  List<String>? bulletPoints;
  String? brand;
  String? manufacturer;
  
  // Pricing
  String? currency;
  double? listPrice;
  double? sellingPrice;
  double? businessPrice;
  
  // Inventory
  int? quantity;
  String? fulfillmentChannel;
  String? availabilityStatus;
  
  // Media
  List<ProductImage>? images;
  ProductVariations? variations;
  
  // Aurora fields
  bool allowChat;
  String? qrData;
  String? brandId;
  bool isLocalBrand;
  String? colorHex;
  String? category;
  String? subcategory;
  Map<String, dynamic>? attributes;
  
  // Methods
  String generateQRData();
  void refreshQRData();
  Map<String, dynamic>? parseQRData();
  String? getProductUrl();
}
```

#### Seller
```dart
class Seller {
  int id;
  String firstname;
  String secondname;
  String thirdname;
  String forthname;
  String email;
  String location;
  String currency;
  int phonenumber;
  int age;
  double? latitude;
  double? longitude;
  
  // Getters
  String get fullName;
  double get discountPercentage;
  int get minimumOrder;
}
```

### Enums

#### AccountType
```dart
enum AccountType {
  seller,
  customer,
  factory,
  distributor,
}
```

#### OrderStatus
```dart
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}
```

#### NotificationType
```dart
enum NotificationType {
  order,
  product,
  system,
  promotion,
  message,
}
```

---

## File Structure

### Complete Directory Tree

```
/workspace
├── lib/
│   ├── main.dart                          # App entry point
│   ├── config/
│   │   ├── supabase_config.dart           # Supabase configuration
│   │   └── performance_config.dart        # Performance settings
│   ├── models/
│   │   ├── aurora_product.dart            # Main product model
│   │   ├── product.dart                   # Amazon-style product
│   │   ├── seller.dart                    # Seller model
│   │   ├── aurora_customer.dart           # Customer model
│   │   ├── aurora_factory.dart            # Factory model
│   │   ├── bill_model.dart                # Bill/invoice model
│   │   ├── nearby_user.dart               # Nearby user model
│   │   ├── product_metadata_template.dart # Metadata template
│   │   ├── auth/
│   │   │   ├── seller.dart                # Auth seller
│   │   │   └── user.dart                  # Auth user
│   │   └── chat/
│   │       └── deal_proposal.dart         # Deal proposal model
│   ├── services/
│   │   ├── auth_provider.dart             # Authentication provider
│   │   ├── product_provider.dart          # Product provider
│   │   ├── supabase.dart                  # Supabase wrapper
│   │   ├── queue_service.dart             # Offline queue
│   │   ├── deal_chat_service.dart         # Chat service
│   │   ├── nearby_chat_service.dart       # Nearby chat
│   │   ├── image_upload_service.dart      # Image upload
│   │   ├── image_caching_service.dart     # Image caching
│   │   ├── offline_queue_service.dart     # Offline operations
│   │   ├── offline_bill_manager.dart      # Offline bills
│   │   ├── production_queue_db.dart       # Production queue
│   │   ├── factories_db.dart              # Factories DB
│   │   ├── factory_materials_db.dart      # Materials DB
│   │   ├── customers_db.dart              # Customers DB
│   │   ├── products_db.dart               # Products DB (service)
│   │   ├── supabase_storage.dart          # Storage wrapper
│   │   ├── secure_storage.dart            # Secure storage
│   │   ├── error_handler.dart             # Error handling
│   │   ├── permissions.dart               # Permissions
│   │   ├── presence_service.dart          # Presence tracking
│   │   ├── vibration_service.dart         # Vibration feedback
│   │   ├── user_preferences_service.dart  # User preferences
│   │   ├── wholesale_pricing_engine.dart  # Wholesale pricing
│   │   └── connectivity_helper.dart       # Connectivity check
│   ├── backend/
│   │   ├── sellerdb.dart                  # Sellers SQLite
│   │   └── products_db.dart               # Products SQLite
│   ├── pages/
│   │   ├── singup/
│   │   │   ├── login.dart                 # Login screen
│   │   │   ├── signup.dart                # Signup screen
│   │   │   └── home.dart                  # Home dashboard
│   │   ├── product/
│   │   │   ├── product.dart               # Product listing
│   │   │   ├── product_form_screen.dart   # Product form
│   │   │   └── brand_data.dart            # Brand data
│   │   ├── customer/
│   │   │   ├── customers_page.dart        # Customers list
│   │   │   ├── customer_form_screen.dart  # Customer form
│   │   │   └── analysis_page.dart         # Customer analysis
│   │   ├── orders/
│   │   │   └── orders_screen.dart         # Orders list
│   │   ├── factory/
│   │   │   └── factories_page.dart        # Factories list
│   │   ├── reviews/
│   │   │   └── reviews_screen.dart        # Reviews
│   │   ├── seller/
│   │   │   └── sellerProfile.dart         # Seller profile
│   │   ├── setting/
│   │   │   └── setting.dart               # Settings
│   │   ├── user/
│   │   │   ├── user_home_page.dart        # User home
│   │   │   ├── user_profile_page.dart     # User profile
│   │   │   ├── user_addresses_page.dart   # Addresses
│   │   │   ├── user_orders_page.dart      # User orders
│   │   │   ├── user_payment_methods_page.dart # Payments
│   │   │   ├── user_wishlist_page.dart    # Wishlist
│   │   │   └── user_pages.dart            # User pages collection
│   │   ├── website/
│   │   │   └── seller_website_dashboard.dart # Seller website
│   │   └── chat/
│   │       └── nearby_users_screen.dart   # Nearby users
│   ├── widgets/
│   │   ├── drawer.dart                    # Navigation drawer
│   │   ├── product_image_upload.dart      # Image upload widget
│   │   ├── deal_proposal_card.dart        # Deal card
│   │   ├── deal_proposal_form_dialog.dart # Deal form dialog
│   │   ├── product_qr_dialog.dart         # QR code dialog
│   │   ├── metadata_form_builder.dart     # Metadata form
│   │   └── language_selector.dart         # Language selector
│   ├── theme/
│   │   └── themeprovider.dart             # Theme management
│   ├── l10n/
│   │   ├── app_localizations.dart         # Localization base
│   │   ├── app_localizations_en.dart      # English translations
│   │   └── app_localizations_ar.dart      # Arabic translations
│   ├── helpers/
│   │   └── secure_data_helper.dart        # Secure data helpers
│   ├── managers/
│   │   └── supply_chain_flow_manager.dart # Supply chain manager
│   ├── screens/
│   │   └── chat/
│   │       └── nearby_users_screen.dart   # Nearby users screen
│   └── utils/
│       ├── json_helpers.dart              # JSON utilities
│       ├── secure_data_helper.dart        # Security helpers
│       └── connectivity_helper.dart       # Connectivity utils
├── supabase/
│   ├── complete_setup.sql                 # Full DB setup
│   ├── database_schema.sql                # Schema definition
│   ├── enhanced_schema.sql                # Enhanced schema
│   ├── quick_setup.sql                    # Quick setup
│   ├── products_schema.sql                # Products schema
│   ├── sellers_table.sql                  # Sellers table
│   ├── fix_sellers_table.sql              # Sellers fix
│   ├── atall.sql                          # Additional SQL
│   ├── jo.sql                             # Jordan SQL
│   ├── notifications.sql                  # Notifications schema
│   ├── config.toml                        # Supabase config
│   ├── functions/                         # Edge functions
│   ├── migrations/                        # DB migrations
│   └── *.ps1                              # Deployment scripts
├── android/                               # Android platform
├── ios/                                   # iOS platform
├── web/                                   # Web platform
├── windows/                               # Windows platform
├── macos/                                 # macOS platform
├── test/                                  # Test files
│   ├── unit/                              # Unit tests
│   ├── widget/                            # Widget tests
│   ├── integration/                       # Integration tests
│   ├── mocks/                             # Mock objects
│   ├── helpers/                           # Test helpers
│   └── sql/                               # SQL tests
├── pubspec.yaml                           # Dependencies
├── pubspec.lock                           # Locked dependencies
├── analysis_options.yaml                  # Linter rules
├── devtools_options.yaml                  # DevTools config
├── l10n.yaml                              # Localization config
└── *.bat, *.ps1                           # Build/test scripts
```

---

## Testing

### Run Tests
```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Integration tests
flutter test test/integration/

# All tests
flutter test
```

### Test Files
- `test/unit/` - Unit tests for services and models
- `test/widget/` - Widget tests for UI components
- `test/integration/` - Integration tests for full flows
- `test/mocks/` - Mock objects for testing
- `test/helpers/` - Test helper utilities

---

## Deployment

### Build APK
```bash
flutter build apk --dart-define-from-file=.env
```

### Build iOS
```bash
flutter build ios --dart-define-from-file=.env
```

### Deploy Supabase Functions
```bash
cd supabase
supabase functions deploy
```

### Set Production Secrets
```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

---

## Security Notes

1. **Never commit `.env` files** with real credentials
2. **Use environment variables** or secret management services
3. **Rotate keys regularly**
4. **Enable RLS (Row Level Security)** on all Supabase tables
5. **Use HTTPS** for all network communications
6. **Validate user input** on both client and server
7. **Implement rate limiting** for API endpoints

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Submit a pull request

---

## License

[Your License Here]

---

## Support

For issues and questions, please open an issue on the repository.

---

*Last Updated: 2026-03-14*
