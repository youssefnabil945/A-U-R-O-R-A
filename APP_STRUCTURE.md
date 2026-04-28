# 🌌 Aurora - Multi-Role E-commerce Marketplace Platform

## Comprehensive Application Structure

This document outlines the complete structure of the Aurora platform, organized by user roles and navigation flows using a fixed drawer navigation system.

---

## 📋 Table of Contents

1. [User Roles Overview](#-user-roles-overview)
2. [Navigation Architecture](#-navigation-architecture)
3. [E-commerce Route (Customer)](#-e-commerce-route-customer)
4. [Seller Route](#-seller-route)
5. [Factory Route](#-factory-route)
6. [Middleman Route](#-middleman-route)
7. [Shared Components](#-shared-components)
8. [Database Structure](#-database-structure)
9. [File Organization](#-file-organization)

---

## 👥 User Roles Overview

| Role | Description | Access Level |
|------|-------------|--------------|
| **Customer** | Users who buy products from the marketplace | E-commerce features, cart, wallet, orders |
| **Seller** | Shop owners who sell products online | Product management, customer management, sales, bills |
| **Factory** | Manufacturers who want to increase sales | Product creation, seller deals, production tracking |
| **Middleman** | Commission-based sellers without inventory | Deal facilitation, commission tracking |

---

## 🧭 Navigation Architecture

### Fixed Drawer Navigation System

The app uses a **fixed drawer** pattern for navigation across all routes. Each role has its own customized drawer with role-specific menu items.

```
┌─────────────────────────────────────┐
│  Header (User Info + Account Type)  │
├─────────────────────────────────────┤
│  🏠 Home                            │
│  ─────────────────────────────────  │
│  Role-Specific Menu Items           │
│  • Seller: Profile, Products, etc.  │
│  • Factory: Dashboard, Products...  │
│  • Customer: Shop, Cart, Wallet     │
│  • Middleman: Deals, Commission     │
│  ─────────────────────────────────  │
│  ⚙️ Settings (Shared)               │
│  💳 Wallet (Shared)                 │
│  🛒 Cart (E-commerce)               │
│  ❓ Help                            │
├─────────────────────────────────────┤
│  Footer (Logout)                    │
└─────────────────────────────────────┘
```

---

## 🛍️ E-commerce Route (Customer)

### Main Pages

| Page | Route | Description | Database |
|------|-------|-------------|----------|
| **Products Page** (Home) | `/shop/home` | Main product listing with filters | `products`, `sellers` |
| **Cart Page** | `/shop/cart` | Shopping cart management | `cart_items` (local) |
| **Wallet Page** | `/shop/wallet` | Digital wallet & payment methods | `wallets`, `payment_methods` |
| **Checkout Page** | `/shop/checkout` | Order placement | `orders`, `order_items` |
| **Settings Page** | `/settings` | App-wide settings (shared) | `user_preferences` |

### Features

#### Products Page
- ✅ Product grid/list view
- ✅ Advanced filtering (category, price, brand, rating)
- ✅ Search functionality
- ✅ Product details with QR/SKU
- ✅ Add to cart
- ✅ Share product

#### Cart Page
- ✅ View cart items
- ✅ Update quantities
- ✅ Remove items
- ✅ Apply discounts
- ✅ Proceed to checkout

#### Wallet Page
- ✅ Balance display
- ✅ Add funds
- ✅ Payment history
- ✅ Saved payment methods

### Drawer Menu Items (Customer)
```
├── 🏠 Home (Products)
├── 🛍️ Shop
├── 🛒 Cart
├── 💳 Wallet
├── 📦 My Orders
├── ❤️ Wishlist
├── ⚙️ Settings (Shared)
├── ❓ Help
└── 🚪 Logout
```

---

## 🏪 Seller Route

### Main Pages

| Page | Route | Description | Database |
|------|-------|-------------|----------|
| **Home/Dashboard** | `/seller/dashboard` | Sales overview, analytics | `sales`, `analytics_snapshots` |
| **Seller Profile** | `/seller/profile` | Profile management | `sellers` |
| **Products Page** | `/seller/products` | Product list & creation | `products` |
| **Create Product** | `/seller/products/create` | New product form | `products` |
| **Customers Page** | `/seller/customers` | Customer management | `customers` |
| **Customer Details** | `/seller/customers/:id` | Grid/Table view with bills | `customers`, `sales` |
| **Sales Page** | `/seller/sales` | Sales history | `sales` |
| **Analytics Page** | `/seller/analytics` | Business insights | `analytics_snapshots` |
| **Messages** | `/seller/messages` | Chat with buyers | `chat_messages`, `chat_rooms` |
| **Factories Page** | `/seller/factories` | Factory deals | `factories`, `deals` |
| **Bills Page** | `/seller/bills` | Bill creation & management | `bills`, `bill_items` |
| **Settings** | `/settings` | Shared settings | `user_preferences` |

### Features

#### Seller Profile
- ✅ Account information (UUID, name, email)
- ✅ Verification status
- ✅ Location & currency
- ✅ Contact details
- ✅ Sync with Supabase

#### Products Management
- ✅ Product list (grid/table view)
- ✅ Create product with ASIN generation
- ✅ QR Code / SKU integration
- ✅ Image upload
- ✅ Inventory tracking
- ✅ Share product links

#### Customers Management
- ✅ Customer list with search
- ✅ **Grid View**: Two-column layout showing customer cards
- ✅ **Table View**: Tabular data with bill access
- ✅ Click on grid tile → View all bills for that customer
- ✅ Customer statistics (total orders, spent, last purchase)
- ✅ Age range demographics

#### Bills Management
- ✅ Create new bill
- ✅ Access products from product database
- ✅ Link bill to customer
- ✅ Payment status tracking
- ✅ Bill history per customer

#### Factories Page (Seller Side)
- ✅ Browse available factories
- ✅ Create deals with factories
- ✅ Track deal status
- ✅ Commission negotiation

### Drawer Menu Items (Seller)
```
├── 🏠 Home (Dashboard)
├── 👤 Seller Profile
├── 📦 Products
│   └── ➕ Create Product
├── 👥 Customers
├── 💰 Sales
├── 📊 Analytics
├── 🏭 Factories (Deals)
├── 💬 Messages
├── 📄 Bills
├── ⚙️ Settings (Shared)
├── ❓ Help
└── 🚪 Logout
```

---

## 🏭 Factory Route

### Main Pages

| Page | Route | Description | Database |
|------|-------|-------------|----------|
| **Home/Dashboard** | `/factory/dashboard` | Production overview, deals | `factories`, `deals` |
| **Products Page** | `/factory/products` | Factory product catalog | `products` |
| **Create Product** | `/factory/products/create` | New product form | `products` |
| **Seller List** | `/factory/sellers` | Connected sellers | `sellers`, `deals` |
| **Create Bill for Seller** | `/factory/bills/create` | Bill creation for sellers | `bills`, `bill_items` |
| **Share Bill** | `/factory/bills/:id/share` | Share bill functionality | `bills` |
| **Sales & Analysis** | `/factory/analytics` | Sales metrics, insights | `analytics_snapshots` |
| **Settings** | `/settings` | Shared settings | `user_preferences` |

### Features

#### Factory Dashboard
- ✅ Production overview
- ✅ Active deals with sellers
- ✅ Revenue tracking
- ✅ Pending orders

#### Products Management
- ✅ Product catalog
- ✅ Create factory products
- ✅ Bulk product upload
- ✅ Product variants

#### Seller List
- ✅ View connected sellers
- ✅ Deal history per seller
- ✅ Performance metrics
- ✅ Communication channel

#### Bill Creation (for Sellers)
- ✅ Select seller
- ✅ Add products
- ✅ Set quantities & prices
- ✅ Generate bill
- ✅ Share via WhatsApp, Email, SMS

#### Sales & Analysis
- ✅ Sales trends
- ✅ Top performing products
- ✅ Seller performance
- ✅ Production efficiency

### Drawer Menu Items (Factory)
```
├── 🏠 Home (Dashboard)
├── 📦 Products
│   └── ➕ Create Product
├── 🏪 Seller List
├── 📄 Create Bill (for Seller)
├── 📊 Sales & Analysis
├── 💬 Messages
├── ⚙️ Settings (Shared)
├── ❓ Help
└── 🚪 Logout
```

---

## 🤝 Middleman Route

### Main Pages

| Page | Route | Description | Database |
|------|-------|-------------|----------|
| **Login** | `/middleman/login` | Authentication | `auth.users` |
| **Signup** | `/middleman/signup` | Registration | `auth.users`, `sellers` |
| **Dashboard** | `/middleman/dashboard` | Deal overview | `deals`, `commissions` |
| **Available Deals** | `/middleman/deals` | Browse deals | `deals`, `products` |
| **My Commissions** | `/middleman/commissions` | Commission tracking | `commissions` |
| **Messages** | `/middleman/messages` | Chat with parties | `chat_messages` |
| **Settings** | `/settings` | Shared settings | `user_preferences` |

### Features

#### Dashboard
- ✅ Active deals count
- ✅ Total commission earned
- ✅ Pending negotiations
- ✅ Recent activity

#### Deal Management
- ✅ Browse available deals
- ✅ Filter by category, commission rate
- ✅ Submit deal proposals
- ✅ Track deal status

#### Commission Tracking
- ✅ Commission history
- ✅ Pending payments
- ✅ Payment requests
- ✅ Export reports

### Drawer Menu Items (Middleman)
```
├── 🏠 Home (Dashboard)
├── 💼 Available Deals
├── 💰 My Commissions
├── 📊 Analytics
├── 💬 Messages
├── ⚙️ Settings (Shared)
├── ❓ Help
└── 🚪 Logout
```

---

## 🔧 Shared Components

### Settings Page (All Routes)
Accessible from all user roles with role-specific sections:

| Section | Description |
|---------|-------------|
| **Profile Settings** | Name, email, phone, avatar |
| **Security** | Password, biometric auth, 2FA |
| **Notifications** | Push, email, SMS preferences |
| **Language** | English, Arabic (RTL support) |
| **Theme** | Light, Dark, System default |
| **Payment Methods** | Saved cards, wallets |
| **Addresses** | Shipping addresses |
| **Privacy** | Data sharing preferences |
| **About** | App version, terms, privacy policy |

### Common Widgets
- ✅ **AppDrawer**: Role-aware navigation drawer
- ✅ **ProductCard**: Reusable product display
- ✅ **CustomerCard**: Customer grid item
- ✅ **BillCard**: Bill summary display
- ✅ **DealProposalCard**: Deal negotiation UI
- ✅ **QRCodeDialog**: QR code generation & sharing
- ✅ **ImageUpload**: Product image handling

---

## 🗄️ Database Structure

### Core Tables

```sql
-- Users & Authentication
auth.users (Supabase Auth)
sellers (seller profiles)
customers (customer profiles)
factories (factory profiles)
middlewares (middleman profiles)

-- Products & Inventory
products (product catalog)
product_variants (product variations)
categories (product categories)
brands (product brands)

-- Sales & Orders
sales (sale records)
orders (customer orders)
order_items (order line items)
bills (bill documents)
bill_items (bill line items)

-- Financial
wallets (user wallets)
payment_methods (saved cards)
commissions (commission records)
transactions (financial transactions)

-- Communication
chat_rooms (chat conversations)
chat_messages (messages)
deal_proposals (deal negotiations)

-- Analytics
analytics_snapshots (cached analytics)
user_preferences (app settings)
```

### Key Relationships

```
┌─────────────┐       ┌─────────────┐
│   sellers   │◄──────│   products  │
└──────┬──────┘       └──────┬──────┘
       │                     │
       │                     │
       ▼                     ▼
┌─────────────┐       ┌─────────────┐
│  customers  │◄──────│    sales    │
└──────┬──────┘       └──────┬──────┘
       │                     │
       │                     │
       ▼                     ▼
┌─────────────┐       ┌─────────────┐
│    bills    │◄──────│  bill_items │
└─────────────┘       └─────────────┘
```

---

## 📁 File Organization

```
A-U-R-O-R-A/
├── lib/
│   ├── main.dart                      # App entry point
│   │
│   ├── backend/                       # Local databases
│   │   ├── sellerdb.dart             # Seller local DB
│   │   ├── products_db.dart          # Products local DB
│   │   ├── customerdb.dart           # Customer local DB
│   │   └── factorydb.dart            # Factory local DB
│   │
│   ├── models/                        # Data models
│   │   ├── user.dart
│   │   ├── seller.dart
│   │   ├── customer.dart
│   │   ├── factory.dart
│   │   ├── middleman.dart
│   │   ├── product.dart
│   │   ├── sale.dart
│   │   ├── order.dart
│   │   ├── bill.dart
│   │   ├── wallet.dart
│   │   ├── cart.dart
│   │   ├── payment_method.dart
│   │   ├── chat_message.dart
│   │   └── deal_proposal.dart
│   │
│   ├── pages/                         # Application screens
│   │   │
│   │   ├── shop/                      # E-commerce (Customer)
│   │   │   ├── home_page.dart        # Products page (main)
│   │   │   ├── cart_page.dart
│   │   │   ├── checkout_page.dart
│   │   │   ├── wallet_page.dart
│   │   │   ├── product_details.dart
│   │   │   └── wishlist_page.dart
│   │   │
│   │   ├── seller/                    # Seller Route
│   │   │   ├── dashboard_page.dart   # Home page
│   │   │   ├── seller_profile.dart
│   │   │   ├── products/
│   │   │   │   ├── products_page.dart
│   │   │   │   └── create_product.dart
│   │   │   ├── customers/
│   │   │   │   ├── customers_page.dart      # List view
│   │   │   │   ├── customer_grid_view.dart  # Grid (2 columns)
│   │   │   │   ├── customer_table_view.dart # Table view
│   │   │   │   └── customer_bills.dart      # All bills for customer
│   │   │   ├── sales/
│   │   │   │   ├── sales_page.dart
│   │   │   │   └── create_bill.dart
│   │   │   ├── factories/
│   │   │   │   └── factories_page.dart      # Factory deals
│   │   │   └── analytics/
│   │   │       └── analytics_page.dart
│   │   │
│   │   ├── factory/                   # Factory Route
│   │   │   ├── dashboard_page.dart   # Home page
│   │   │   ├── products/
│   │   │   │   ├── products_page.dart
│   │   │   │   └── create_product.dart
│   │   │   ├── sellers/
│   │   │   │   └── sellers_list.dart
│   │   │   ├── bills/
│   │   │   │   ├── create_bill.dart
│   │   │   │   └── share_bill.dart
│   │   │   └── analytics/
│   │   │       └── sales_analysis.dart
│   │   │
│   │   ├── middleman/                 # Middleman Route
│   │   │   ├── login_page.dart
│   │   │   ├── signup_page.dart
│   │   │   ├── dashboard_page.dart
│   │   │   ├── deals_page.dart
│   │   │   └── commissions_page.dart
│   │   │
│   │   ├── setting/                   # Shared Settings
│   │   │   └── settings_page.dart
│   │   │
│   │   ├── auth/                      # Authentication
│   │   │   ├── login_page.dart
│   │   │   ├── signup_page.dart
│   │   │   └── role_selection.dart
│   │   │
│   │   └── onboarding/                # Onboarding flow
│   │       ├── welcome_page.dart
│   │       └── role_selection_page.dart
│   │
│   ├── services/                      # Business logic
│   │   ├── supabase.dart             # Supabase client
│   │   ├── auth_service.dart         # Authentication
│   │   ├── auth_provider.dart        # Auth state management
│   │   ├── product_provider.dart     # Product state
│   │   ├── notification_service.dart
│   │   ├── presence_service.dart
│   │   └── edge_functions.dart       # Serverless functions
│   │
│   ├── widgets/                       # Reusable components
│   │   ├── drawer.dart               # Fixed drawer navigation
│   │   ├── product_card.dart
│   │   ├── customer_card.dart
│   │   ├── bill_card.dart
│   │   ├── deal_proposal_card.dart
│   │   ├── deal_proposal_form_dialog.dart
│   │   ├── product_image_upload.dart
│   │   ├── product_qr_dialog.dart
│   │   └── metadata_form_builder.dart
│   │
│   ├── theme/                         # Theming
│   │   └── themeprovider.dart
│   │
│   ├── config/                        # Configuration
│   │   └── supabase_config.dart
│   │
│   └── l10n/                          # Localization
│       └── app_localizations.dart
│
├── supabase/
│   ├── functions/                     # Edge functions
│   │   ├── create-order/
│   │   ├── process-payment/
│   │   ├── generate-analytics/
│   │   └── send-notification/
│   │
│   └── migrations/                    # Database migrations
│       ├── 001_initial_schema.sql
│       ├── 002_products_schema.sql
│       ├── 003_sales_customers.sql
│       ├── 004_chat_system.sql
│       └── 005_analytics_complete.sql
│
├── test/                              # Tests
│   ├── unit/
│   └── widget/
│
└── pubspec.yaml                       # Dependencies
```

---

## 🎯 Implementation Priority

### Phase 1: Core Infrastructure ✅
- [x] Multi-role authentication
- [x] Fixed drawer navigation
- [x] Shared settings page
- [x] Basic product management

### Phase 2: E-commerce Route 🔄
- [x] Products page with filters
- [x] Cart functionality
- [x] Wallet integration
- [ ] Checkout flow completion
- [ ] Order tracking

### Phase 3: Seller Route 🔄
- [x] Seller dashboard
- [x] Seller profile
- [x] Product management
- [x] Customer management (grid/table views)
- [ ] Bill creation system
- [ ] Factory deals integration

### Phase 4: Factory Route 📋
- [ ] Factory dashboard
- [ ] Product creation
- [ ] Seller list
- [ ] Bill creation for sellers
- [ ] Bill sharing
- [ ] Sales analysis

### Phase 5: Middleman Route 📋
- [x] Login/Signup
- [ ] Dashboard
- [ ] Deal browsing
- [ ] Commission tracking
- [ ] Messaging

---

## 📱 Navigation Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      Welcome Page                             │
│                    (Role Selection)                           │
└────────────────────────┬─────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│   Customer    │ │    Seller     │ │   Factory     │
│   (E-comm)    │ │   (Shop)      │ │  (Manufacture)│
└───────┬───────┘ └───────┬───────┘ └───────┬───────┘
        │                 │                 │
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│  Products     │ │  Dashboard    │ │  Dashboard    │
│  (Main Page)  │ │  (Home)       │ │  (Home)       │
└───────┬───────┘ └───────┬───────┘ └───────┬───────┘
        │                 │                 │
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│  Cart/Wallet  │ │  Products/    │ │  Products/    │
│               │ │  Customers/   │ │  Sellers/     │
│               │ │  Sales/Bills  │ │  Bills        │
└───────────────┘ └───────────────┘ └───────────────┘
        │                 │                 │
        └────────────────┼─────────────────┘
                         │
                         ▼
              ┌───────────────────┐
              │  Settings (Shared)│
              │  Wallet (Shared)  │
              │  Help (Shared)    │
              └───────────────────┘
```

---

## 🔐 Security Considerations

1. **Row Level Security (RLS)**: All tables use RLS for data isolation
2. **Role-based Access**: Each role can only access their authorized resources
3. **Secure Storage**: Sensitive data encrypted in local storage
4. **Biometric Auth**: Optional fingerprint/face recognition
5. **Session Management**: Automatic token refresh and expiration handling

---

## 📊 Performance Optimizations

1. **Caching**: Analytics snapshots cached for fast retrieval
2. **Lazy Loading**: Images and lists loaded on demand
3. **Pagination**: Large datasets paginated
4. **Real-time Updates**: Supabase Realtime for live data
5. **Offline Support**: Local database for offline access

---

## 🌍 Localization

- ✅ English (Default)
- ✅ Arabic (RTL Support)
- 🔄 Expandable to other languages

---

## 📞 Support & Documentation

For detailed implementation guides, refer to:
- `COMPLETE_IMPLEMENTATION_SUMMARY.md`
- `BACKEND_FUNCTIONS_COMPLETE_GUIDE.md`
- `CHAT_SYSTEM_ARCHITECTURE.md`
- `PRODUCT_SYSTEM_GUIDE.md`

---

**Last Updated**: April 2026  
**Version**: 2.0.0  
**Platform**: iOS | Android | Web
