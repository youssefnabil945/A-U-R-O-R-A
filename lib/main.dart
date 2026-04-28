// ============================================================================
// Aurora E-commerce Platform - Main Entry Point
// ============================================================================
//
// Features:
// - User Authentication (Login/Signup)
// - Seller Support
// - Real-time Chat with Deal Negotiation
// - Product Management & Sales Tracking
// - Commission-based Deal System
// - Biometric Authentication
// - Theme Customization
// - System Theme Detection
//
// Chat & Deal Features:
// - Real-time messaging (Supabase Realtime)
// - Text, Image, and File messages
// - Deal proposals within chat conversations
// - Commission rate negotiation
// - Deal status tracking (pending → accepted/rejected)
// - Typing indicators and read receipts
//
// Database: Supabase (PostgreSQL + Realtime)
// Architecture: Modular providers for better maintainability
// Performance: Optimized with caching, pagination, lazy loading
// ============================================================================

import 'package:aurora/backend/sellerdb.dart';
import 'package:aurora/backend/products_db.dart';
import 'package:aurora/config/supabase_config.dart';
import 'package:aurora/pages/onboarding/welcome_page.dart';
import 'package:aurora/pages/onboarding/role_selection_page.dart';
import 'package:aurora/pages/shop/home_page.dart';
import 'package:aurora/pages/shop/cart_page.dart';
import 'package:aurora/pages/shop/checkout_page.dart';
import 'package:aurora/pages/shop/wallet_page.dart';
import 'package:aurora/pages/middleman/middleman_login_page.dart';
import 'package:aurora/pages/middleman/middleman_signup_page.dart';
import 'package:aurora/pages/seller/seller_login_page.dart';
import 'package:aurora/pages/seller/seller_dashboard_page.dart';
import 'package:aurora/pages/seller/sellerProfile.dart';
import 'package:aurora/pages/factory/factory_login_page.dart';
import 'package:aurora/pages/factory/factory_dashboard_page.dart';
import 'package:aurora/pages/product/product.dart';
import 'package:aurora/pages/customers/customers_page.dart';
import 'package:aurora/pages/analytics/analytics_page.dart';
import 'package:aurora/pages/setting/setting.dart';
import 'package:aurora/pages/singup/home.dart';
import 'package:aurora/pages/singup/login.dart';
import 'package:aurora/services/supabase.dart';
import 'package:aurora/services/auth_provider.dart';
import 'package:aurora/services/product_provider.dart';
import 'package:aurora/services/permissions.dart';
import 'package:aurora/services/notification_service.dart';
import 'package:aurora/services/user_preferences_service.dart';
import 'package:aurora/services/presence_service.dart';
import 'package:aurora/services/role_sandbox_service.dart';
import 'package:aurora/theme/themeprovider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/models/wallet.dart';
import 'package:aurora/models/cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate configuration
  final configError = SupabaseConfig.validate();
  if (configError != null) {
    debugPrint('⚠️ CONFIGURATION ERROR: $configError');
    debugPrint('Please set environment variables:');
    debugPrint('  --dart-define=SUPABASE_URL=your_url');
    debugPrint('  --dart-define=SUPABASE_ANON_KEY=your_key');
    debugPrint('  OR create .env file from .env.example');
    return; // Abort startup to avoid initializing Supabase with invalid config
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
      detectSessionInUri: true,
    ),
  );

  // Request permissions on first launch
  await AppPermissions.requestPermissions();

  // Initialize databases
  final sellerDb = SellerDB();
  final productsDb = ProductsDB();

  // Initialize services
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  final userPreferencesService = UserPreferencesService();
  await userPreferencesService.initialize();

  final notificationService = NotificationService();
  final presenceService = PresenceService();

  // Initialize modular providers
  final supabaseProvider = SupabaseProvider(
    Supabase.instance.client,
    sellerDb,
    productsDb,
  );
  final authProvider = AuthProvider(
    Supabase.instance.client,
    sellerDb,
    productsDb,
  );
  final productProvider = ProductProvider(Supabase.instance.client, productsDb);

  // Wait for DBs to initialize
  await Future.delayed(const Duration(milliseconds: 300));

  runApp(
    MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider.value(value: supabaseProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: productProvider),
        ChangeNotifierProvider.value(value: notificationService),
        ChangeNotifierProvider.value(value: userPreferencesService),
        ChangeNotifierProvider.value(value: presenceService),
        
        // Customer E-commerce providers
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        
        // Local databases
        ChangeNotifierProvider(create: (_) => sellerDb),
        Provider(create: (_) => productsDb),
        
        // Queue service
        Provider(create: (_) => authProvider.queue),
        
        // Theme
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const Aurora(),
    ),
  );
}

class Aurora extends StatelessWidget {
  const Aurora({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, ThemeProvider, UserPreferencesService>(
      builder: (context, authProvider, themeProvider, userPrefs, child) {
        // Update theme with system brightness
        final systemBrightness = MediaQuery.platformBrightnessOf(context);
        themeProvider.updateSystemBrightness(systemBrightness);

        // Initialize services when logged in
        if (authProvider.isLoggedIn && !authProvider.isCheckingSession) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<NotificationService>().initialize(authProvider.userId!);
          });
        }

        return _buildMaterialApp(
          context,
          authProvider,
          themeProvider,
          userPrefs.locale,
        );
      },
    );
  }

  Widget _buildMaterialApp(
    BuildContext context,
    AuthProvider authProvider,
    ThemeProvider themeProvider,
    Locale? locale,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aurora E-commerce',
      theme: themeProvider.themeData,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      locale: locale,
      home: const WelcomePage(),
      routes: {
        '/login': (context) => const Login(),
        '/home': (context) => const Homepage(),
        '/shop/home': (context) => const ShopHomePage(),
        '/shop/cart': (context) => const CartPage(),
        '/shop/checkout': (context) => const CheckoutPage(),
        '/shop/wallet': (context) => const WalletPage(),
        '/middleman/login': (context) => const MiddlemanLoginPage(),
        '/middleman/signup': (context) => const MiddlemanSignupPage(),
        '/seller/login': (context) => const SellerLoginPage(),
        '/seller/dashboard': (context) => const SellerDashboardPage(),
        '/factory/login': (context) => const FactoryLoginPage(),
        '/factory/dashboard': (context) => const FactoryDashboardPage(),
        // Role-based sandbox routes
        '/profile': (context) => _buildProfilePage(context),
        '/products': (context) => _buildProductsPage(context),
        '/customers': (context) => _buildCustomersPage(context),
        '/analytics': (context) => _buildAnalyticsPage(context),
        '/wallet': (context) => const WalletPage(),
        '/settings': (context) => _buildSettingsPage(context),
        '/sellers': (context) => _buildSellersPage(context),
        '/orders': (context) => _buildOrdersPage(context),
      },
    );
  }

  // ============================================================================
  // Role-based Page Builders - These ensure users stay within their sandbox
  // ============================================================================
  
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
        // Factory profile is part of factory dashboard - use placeholder for now
        return const FactoryProfilePlaceholder();
      default:
        return const UserProfilePage();
    }
  }

  Widget _buildProductsPage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sandboxService = RoleSandboxService();
    
    if (!sandboxService.isModuleAllowed(authProvider.userRole, AppModule.products)) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }
    
    return const ProductPage();
  }

  Widget _buildCustomersPage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sandboxService = RoleSandboxService();
    
    if (!sandboxService.isModuleAllowed(authProvider.userRole, AppModule.customers)) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }
    
    return const CustomersPage();
  }

  Widget _buildAnalyticsPage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sandboxService = RoleSandboxService();
    
    if (!sandboxService.isModuleAllowed(authProvider.userRole, AppModule.analytics)) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }
    
    return const AnalyticsPage();
  }

  Widget _buildSettingsPage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sandboxService = RoleSandboxService();
    
    if (!sandboxService.isModuleAllowed(authProvider.userRole, AppModule.settings)) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }
    
    return const Setting();
  }

  Widget _buildSellersPage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sandboxService = RoleSandboxService();
    
    if (!sandboxService.isModuleAllowed(authProvider.userRole, AppModule.sellers)) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }
    
    return const SellersListPage();
  }

  Widget _buildOrdersPage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sandboxService = RoleSandboxService();
    
    if (!sandboxService.isModuleAllowed(authProvider.userRole, AppModule.orders)) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }
    
    return const OrdersPage();
  }
}

// ============================================================================
// Placeholder pages for future implementation
// ============================================================================

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('User Profile'));
}

class FactoryProfilePlaceholder extends StatelessWidget {
  const FactoryProfilePlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Factory Profile'));
}

class SellersListPage extends StatelessWidget {
  const SellersListPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Sellers List'));
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Orders'));
}

class DistributorDashboardPage extends StatelessWidget {
  const DistributorDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Distributor Dashboard - Coming Soon'));
}
