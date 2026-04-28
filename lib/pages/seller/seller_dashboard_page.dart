// ============================================================================
// Seller Dashboard - Main landing page after seller login
// ============================================================================
// 
// Provides role-specific navigation with fixed drawer
// Modules: Home, Profile, Products, Customers, Analytics, Wallet, Settings
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/role_sandbox_service.dart';
import '../seller/sellerProfile.dart';
import '../product/product.dart';
import '../customers/customers_page.dart';
import '../analytics/analytics_page.dart';
import '../shop/wallet_page.dart';
import '../setting/setting.dart';

/// Seller Dashboard with fixed drawer navigation
class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  int _selectedIndex = 0;
  final RoleSandboxService _sandboxService = RoleSandboxService();

  // Define seller's navigation items based on allowed modules
  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      module: AppModule.home,
      label: 'Home',
      icon: Icons.home,
    ),
    _NavigationItem(
      module: AppModule.profile,
      label: 'Profile',
      icon: Icons.person,
    ),
    _NavigationItem(
      module: AppModule.products,
      label: 'Products',
      icon: Icons.inventory_2,
    ),
    _NavigationItem(
      module: AppModule.customers,
      label: 'Customers',
      icon: Icons.people,
    ),
    _NavigationItem(
      module: AppModule.analytics,
      label: 'Analytics',
      icon: Icons.analytics,
    ),
    _NavigationItem(
      module: AppModule.wallet,
      label: 'Wallet',
      icon: Icons.account_balance_wallet,
    ),
    _NavigationItem(
      module: AppModule.settings,
      label: 'Settings',
      icon: Icons.settings,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _getPages() {
    return [
      const SellerHomePage(),
      const SellerProfilePageWrapper(),
      const SellerProductsPage(),
      const SellerCustomersPage(),
      const SellerAnalyticsPage(),
      const SellerWalletPage(),
      const SellerSettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/seller/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    final config = _sandboxService.getConfigForRole(UserRole.seller);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(config?.icon ?? Icons.store, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config?.roleName ?? 'Seller',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '@${authProvider.fullName ?? "Seller"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/seller/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Fixed Navigation Rail for large screens
          if (isLargeScreen)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              leading: FloatingActionButton(
                onPressed: () {
                  // Quick add product action
                },
                child: const Icon(Icons.add),
              ),
              destinations: _navigationItems.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.icon, color: config?.primaryColor),
                  label: Text(item.label),
                );
              }).toList(),
            ),
          
          // Main content area
          Expanded(
            child: _getPages()[_selectedIndex],
          ),
        ],
      ),
      // Bottom Navigation for mobile
      bottomNavigationBar: isLargeScreen
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: _navigationItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.icon, color: config?.primaryColor),
                  label: item.label,
                );
              }).toList(),
            ),
    );
  }
}

class _NavigationItem {
  final AppModule module;
  final String label;
  final IconData icon;

  _NavigationItem({
    required this.module,
    required this.label,
    required this.icon,
  });
}

// ============================================================================
// Seller Home Page
// ============================================================================
class SellerHomePage extends StatelessWidget {
  const SellerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${authProvider.fullName ?? "Seller"}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                title: 'Total Sales',
                value: '\$0.00',
                icon: Icons.shopping_bag,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Orders',
                value: '0',
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Customers',
                value: '0',
                icon: Icons.people,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Products',
                value: '0',
                icon: Icons.inventory_2,
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add),
                label: const Text('Add Customer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Wrapper pages for existing implementations
// ============================================================================

class SellerProfilePageWrapper extends StatelessWidget {
  const SellerProfilePageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Import and use existing seller profile page
    return const SellerProfile();
  }
}

class SellerProductsPage extends StatelessWidget {
  const SellerProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Import and use existing products page
    return const ProductPage();
  }
}

class SellerCustomersPage extends StatelessWidget {
  const SellerCustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Import and use existing customers page
    return const CustomersPage();
  }
}

class SellerAnalyticsPage extends StatelessWidget {
  const SellerAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Import and use existing analytics page
    return const AnalyticsPage();
  }
}

class SellerWalletPage extends StatelessWidget {
  const SellerWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Import and use existing wallet page
    return const WalletPage();
  }
}

class SellerSettingsPage extends StatelessWidget {
  const SellerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Import and use existing settings page
    return const Setting();
  }
}

// ============================================================================
// Stat Card Widget
// ============================================================================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
