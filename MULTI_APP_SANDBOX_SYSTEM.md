# Multi-App Sandbox System Documentation

## Overview

This document describes the Docker-like sandboxing system implemented for the Aurora E-commerce Platform. Each user role (Seller, Factory, Customer, Distributor) has its own isolated environment with specific access permissions to different modules/pages.

## Architecture

### Core Components

1. **RoleSandboxService** (`lib/services/role_sandbox_service.dart`)
   - Central service managing role-based access control
   - Defines sandbox configurations for each role
   - Validates module access permissions
   - Provides navigation helpers

2. **UserRole Enum**
   - `seller` - Retail sellers managing products and customers
   - `factory` - Manufacturers managing products and sellers
   - `customer` - End users shopping for products
   - `distributor` - Distribution partners

3. **AppModule Enum**
   - `home` - Dashboard/home page
   - `profile` - User profile management
   - `products` - Product management
   - `customers` - Customer management
   - `analytics` - Analytics and reporting
   - `wallet` - Financial transactions
   - `settings` - App settings
   - `sellers` - Seller discovery (for factories)
   - `orders` - Order management
   - `chat` - Messaging system
   - `notifications` - Notification center

## Role Configurations

### Seller Sandbox

**Pages Available:**
- Home Page - Dashboard with sales statistics
- Profile Page - Seller profile management
- Products Page - Product catalog management
- Customers Page - Customer relationship management
- Analytics Page - Sales analytics and reports
- Wallet Page - Financial transactions
- Settings Page - Account settings

**Navigation:** Fixed drawer (NavigationRail on tablets/PCs, BottomNavigationBar on mobile)

**Color Theme:** Blue

```dart
allowedModules: [
  AppModule.home,
  AppModule.profile,
  AppModule.products,
  AppModule.customers,
  AppModule.analytics,
  AppModule.wallet,
  AppModule.settings,
]
```

### Factory Sandbox

**Pages Available:**
- Home Page - Dashboard with production statistics
- Products Page - Manufacturing product management
- Sellers Page - Discover and manage seller relationships
- Wallet Page - Financial transactions
- Settings Page - Account settings

**Navigation:** Fixed drawer (NavigationRail on tablets/PCs, BottomNavigationBar on mobile)

**Color Theme:** Orange

```dart
allowedModules: [
  AppModule.home,
  AppModule.products,
  AppModule.sellers,
  AppModule.wallet,
  AppModule.settings,
]
```

### Customer Sandbox

**Pages Available:**
- Home Page - Shopping homepage
- Profile Page - User profile
- Products Page - Product browsing
- Orders Page - Order history and tracking
- Wallet Page - Payment methods
- Settings Page - App preferences

**Color Theme:** Green

### Distributor Sandbox

**Pages Available:**
- Home Page - Distribution dashboard
- Products Page - Product catalog
- Orders Page - Order management
- Analytics Page - Distribution analytics
- Settings Page - Account settings

**Color Theme:** Purple

## Implementation Details

### 1. Dashboard Pages

Each role has a dedicated dashboard page that serves as the main entry point:

- **SellerDashboardPage** (`lib/pages/seller/seller_dashboard_page.dart`)
- **FactoryDashboardPage** (`lib/pages/factory/factory_dashboard_page.dart`)

These dashboards feature:
- Responsive design (NavigationRail for large screens, BottomNavigationBar for mobile)
- Role-specific branding (icons, colors)
- Quick statistics overview
- Quick action buttons
- Access control validation

### 2. Route Protection

All routes are protected by the sandbox service in `main.dart`:

```dart
Widget _buildProfilePage(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context);
  final sandboxService = RoleSandboxService();
  
  // Check if user can access profile
  if (!sandboxService.isModuleAllowed(authProvider.userRole, AppModule.profile)) {
    return const Scaffold(
      body: Center(child: Text('Access Denied')),
    );
  }
  
  // Return appropriate profile page based on role
  switch (authProvider.accountType) {
    case AccountType.seller:
      return const SellerProfile();
    case AccountType.factory:
      return const FactoryProfilePage();
    default:
      return const UserProfilePage();
  }
}
```

### 3. Extension Methods

Convenient extension methods on `AuthProvider`:

```dart
extension RoleSandboxExtension on AuthProvider {
  UserRole get userRole {
    switch (accountType) {
      case AccountType.seller:
        return UserRole.seller;
      case AccountType.factory:
        return UserRole.factory;
      // ...
    }
  }

  bool canAccessModule(AppModule module) {
    return RoleSandboxService().isModuleAllowed(userRole, module);
  }
}
```

## Usage Examples

### Checking Module Access

```dart
final authProvider = Provider.of<AuthProvider>(context);

if (authProvider.canAccessModule(AppModule.analytics)) {
  // Show analytics button
}
```

### Navigating Within Sandbox

```dart
final sandboxService = RoleSandboxService();
sandboxService.navigateToModule(context, AppModule.products);
// Will show error snackbar if user doesn't have access
```

### Building Role-Specific UI

```dart
final config = RoleSandboxService().getConfigForRole(UserRole.seller);

AppBar(
  backgroundColor: config?.primaryColor,
  title: Text(config?.roleName ?? 'User'),
  leading: Icon(config?.icon),
)
```

## Security Features

1. **Access Denial**: Users attempting to access unauthorized routes see "Access Denied" screen
2. **Navigation Validation**: All navigation goes through sandbox service validation
3. **Role Verification**: Every page checks user role before rendering
4. **Snackbar Notifications**: Users receive feedback when accessing restricted areas

## Adding New Roles

To add a new role:

1. Add to `UserRole` enum in `role_sandbox_service.dart`
2. Add configuration to `sandboxConfigs` map
3. Define allowed modules
4. Create dashboard page
5. Add route in `main.dart`
6. Update page builders for role-specific pages

## Adding New Modules

To add a new module:

1. Add to `AppModule` enum
2. Update role configurations to include/exclude the module
3. Create the page component
4. Add route protection in `main.dart`

## File Structure

```
lib/
├── services/
│   ├── role_sandbox_service.dart      # Core sandbox logic
│   └── auth_provider.dart             # Authentication with role support
├── pages/
│   ├── seller/
│   │   ├── seller_dashboard_page.dart # Seller's main dashboard
│   │   └── sellerProfile.dart         # Existing seller profile
│   ├── factory/
│   │   ├── factory_dashboard_page.dart # Factory's main dashboard
│   │   └── factory_login_page.dart    # Factory login
│   ├── shop/                          # Customer pages
│   ├── product/                       # Product management
│   ├── customers/                     # Customer management
│   ├── analytics/                     # Analytics pages
│   └── setting/                       # Settings pages
└── main.dart                          # Route definitions with protection
```

## Testing Guidelines

1. Test each role's access to all modules
2. Verify unauthorized access shows denial screen
3. Test responsive navigation (mobile vs tablet/desktop)
4. Verify logout redirects to appropriate login page
5. Test role switching scenarios

## Future Enhancements

1. **Dynamic Permissions**: Database-driven permission system
2. **Custom Roles**: Allow creating custom role combinations
3. **Temporary Access**: Time-limited module access grants
4. **Audit Logging**: Track access attempts and usage patterns
5. **Feature Flags**: Enable/disable features per role dynamically

## Related Documentation

- [BACKEND_FUNCTIONS_COMPLETE_GUIDE.md](./BACKEND_FUNCTIONS_COMPLETE_GUIDE.md)
- [MULTI_ROLE_SYSTEM_IMPLEMENTATION.md](./MULTI_ROLE_SYSTEM_IMPLEMENTATION.md)
- [SECURITY_FIXES_COMPLETE.md](./SECURITY_FIXES_COMPLETE.md)
