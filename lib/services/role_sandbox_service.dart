// ============================================================================
// Role Sandbox Service
// ============================================================================
// 
// Implements Docker-like sandboxing for different user roles
// Each role has isolated access to specific pages and features
// Prevents users from accessing pages outside their role permissions
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

/// Defines the available roles in the system
enum UserRole {
  seller,
  factory,
  customer,
  distributor,
}

/// Defines the available modules/pages in the system
enum AppModule {
  home,
  profile,
  products,
  customers,
  analytics,
  wallet,
  settings,
  sellers, // For factory to view sellers
  orders,
  chat,
  notifications,
}

/// Configuration for each role's sandbox
class RoleSandboxConfig {
  final String roleName;
  final IconData icon;
  final Color primaryColor;
  final List<AppModule> allowedModules;
  final String defaultRoute;
  final Widget Function(BuildContext context) dashboardBuilder;

  const RoleSandboxConfig({
    required this.roleName,
    required this.icon,
    required this.primaryColor,
    required this.allowedModules,
    required this.defaultRoute,
    required this.dashboardBuilder,
  });
}

/// Service that manages role-based sandboxing
class RoleSandboxService {
  static final RoleSandboxService _instance = RoleSandboxService._internal();
  factory RoleSandboxService() => _instance;
  RoleSandboxService._internal();

  /// Sandbox configurations for each role
  final Map<UserRole, RoleSandboxConfig> sandboxConfigs = {
    UserRole.seller: RoleSandboxConfig(
      roleName: 'Seller',
      icon: Icons.store,
      primaryColor: Colors.blue,
      allowedModules: [
        AppModule.home,
        AppModule.profile,
        AppModule.products,
        AppModule.customers,
        AppModule.analytics,
        AppModule.wallet,
        AppModule.settings,
      ],
      defaultRoute: '/seller/dashboard',
      dashboardBuilder: (context) => _buildSellerDashboard(context),
    ),
    UserRole.factory: RoleSandboxConfig(
      roleName: 'Factory',
      icon: Icons.factory,
      primaryColor: Colors.orange,
      allowedModules: [
        AppModule.home,
        AppModule.products,
        AppModule.sellers,
        AppModule.wallet,
        AppModule.settings,
      ],
      defaultRoute: '/factory/dashboard',
      dashboardBuilder: (context) => _buildFactoryDashboard(context),
    ),
    UserRole.customer: RoleSandboxConfig(
      roleName: 'Customer',
      icon: Icons.shopping_cart,
      primaryColor: Colors.green,
      allowedModules: [
        AppModule.home,
        AppModule.profile,
        AppModule.products,
        AppModule.orders,
        AppModule.wallet,
        AppModule.settings,
      ],
      defaultRoute: '/shop/home',
      dashboardBuilder: (context) => _buildCustomerDashboard(context),
    ),
    UserRole.distributor: RoleSandboxConfig(
      roleName: 'Distributor',
      icon: Icons.local_shipping,
      primaryColor: Colors.purple,
      allowedModules: [
        AppModule.home,
        AppModule.products,
        AppModule.orders,
        AppModule.analytics,
        AppModule.settings,
      ],
      defaultRoute: '/distributor/dashboard',
      dashboardBuilder: (context) => _buildDistributorDashboard(context),
    ),
  };

  /// Check if a module is allowed for the current user's role
  bool isModuleAllowed(UserRole role, AppModule module) {
    final config = sandboxConfigs[role];
    if (config == null) return false;
    return config.allowedModules.contains(module);
  }

  /// Get the sandbox config for a role
  RoleSandboxConfig? getConfigForRole(UserRole role) {
    return sandboxConfigs[role];
  }

  /// Get the user's role from AuthProvider
  UserRole getUserRole(AuthProvider authProvider) {
    switch (authProvider.accountType) {
      case AccountType.seller:
        return UserRole.seller;
      case AccountType.factory:
        return UserRole.factory;
      case AccountType.distributor:
        return UserRole.distributor;
      case AccountType.customer:
      default:
        return UserRole.customer;
    }
  }

  /// Navigate to a module within the user's sandbox
  void navigateToModule(BuildContext context, AppModule module) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = getUserRole(authProvider);
    
    if (!isModuleAllowed(userRole, module)) {
      _showAccessDeniedSnackbar(context, module);
      return;
    }

    final route = _getRouteForModule(module);
    if (route != null) {
      Navigator.of(context).pushNamed(route);
    }
  }

  /// Build the appropriate dashboard based on user role
  Widget buildRoleDashboard(BuildContext context, AuthProvider authProvider) {
    if (!authProvider.isLoggedIn) {
      return const Center(child: Text('Please login to continue'));
    }

    final userRole = getUserRole(authProvider);
    final config = sandboxConfigs[userRole];
    
    if (config == null) {
      return const Center(child: Text('Unknown user role'));
    }

    return config.dashboardBuilder(context);
  }

  String? _getRouteForModule(AppModule module) {
    switch (module) {
      case AppModule.home:
        return null; // Already on dashboard
      case AppModule.profile:
        return '/profile';
      case AppModule.products:
        return '/products';
      case AppModule.customers:
        return '/customers';
      case AppModule.analytics:
        return '/analytics';
      case AppModule.wallet:
        return '/wallet';
      case AppModule.settings:
        return '/settings';
      case AppModule.sellers:
        return '/sellers';
      case AppModule.orders:
        return '/orders';
      case AppModule.chat:
        return '/chat';
      case AppModule.notifications:
        return '/notifications';
      default:
        return null;
    }
  }

  void _showAccessDeniedSnackbar(BuildContext context, AppModule module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access denied: $module is not available for your role'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Dashboard builders
  static Widget _buildSellerDashboard(BuildContext context) {
    // Import here to avoid circular dependencies
    return const SellerDashboardPage();
  }

  static Widget _buildFactoryDashboard(BuildContext context) {
    return const FactoryDashboardPage();
  }

  static Widget _buildCustomerDashboard(BuildContext context) {
    return const ShopHomePage();
  }

  static Widget _buildDistributorDashboard(BuildContext context) {
    return const DistributorDashboardPage();
  }
}

/// Extension to check module permissions easily
extension RoleSandboxExtension on AuthProvider {
  UserRole get userRole {
    switch (accountType) {
      case AccountType.seller:
        return UserRole.seller;
      case AccountType.factory:
        return UserRole.factory;
      case AccountType.distributor:
        return UserRole.distributor;
      case AccountType.customer:
      default:
        return UserRole.customer;
    }
  }

  bool canAccessModule(AppModule module) {
    return RoleSandboxService().isModuleAllowed(userRole, module);
  }
}
