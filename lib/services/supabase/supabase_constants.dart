// ============================================================================
// Supabase Constants & Configuration
// ============================================================================
// 
// Centralized constants for Supabase operations.
// Note: For Supabase URL and keys, use SupabaseConfig from config/supabase_config.dart
// ============================================================================

/// Constants for Supabase operations
class SupabaseConstants {
  SupabaseConstants._();

  // ==========================================================================
  // Cache Configuration
  // ==========================================================================
  
  static const Duration cacheDuration = Duration(minutes: 5);
  static const Duration analyticsCacheDuration = Duration(minutes: 15);
  static const String cacheExpiry = 'cache_expiry';

  // Cache Keys - Core
  static const String cacheAnalytics = 'cache_analytics';
  static const String cacheCategories = 'cache_categories';
  static const String cacheProducts = 'cache_products';
  static const String cacheSellerProfile = 'cache_seller_profile';

  // Deprecated cache keys (kept for backward compatibility)
  @Deprecated('Customer profile is now seller-managed')
  static const String cacheCustomerProfile = 'cache_customer_profile';
  
  @Deprecated('Deals system removed with middleman role')
  static const String cacheDeals = 'cache_deals';

  // ==========================================================================
  // Edge Functions
  // ==========================================================================
  
  // Auth Functions
  static const String functionProcessSignup = 'process-signup';
  static const String functionProcessLogin = 'process-login';
  
  // Product Functions
  static const String functionCreateProduct = 'create-product';
  static const String functionUpdateProduct = 'update-product';
  static const String functionDeleteProduct = 'delete-product';
  static const String functionListProducts = 'list-products';
  static const String functionSearchProducts = 'search-products';
  static const String functionManageProduct = 'manage-product';
  
  // Order Functions
  static const String functionCreateOrder = 'create-order';
  
  // Chat Functions
  static const String functionGetOrCreateConversation = 'get-or-create-conversation';
  
  // Notification Functions
  static const String functionProcessNotification = 'process-notification';

  // Deprecated functions (kept for backward compatibility)
  @Deprecated('Middleman role removed')
  static const String functionCreateDeal = 'create-deal';

  // ==========================================================================
  // Database Tables
  // ==========================================================================
  
  // Core Tables
  static const String tableSellers = 'sellers';
  static const String tableProducts = 'products';
  static const String tableOrders = 'orders';
  static const String tableOrderItems = 'order_items';
  static const String tableCustomers = 'customers';
  static const String tableReviews = 'reviews';
  static const String tableCart = 'cart';
  static const String tableWishlist = 'wishlist';
  static const String tableShippingAddresses = 'shipping_addresses';
  
  // Chat Tables
  static const String tableConversations = 'conversations';
  static const String tableMessages = 'messages';
  
  // Analytics & Notifications
  static const String tableAnalytics = 'analytics';
  static const String tableNotifications = 'notifications';
  static const String tableCategories = 'categories';

  // Deprecated tables (kept for backward compatibility)
  @Deprecated('Deals system removed with middleman role')
  static const String tableDeals = 'deals';
  
  @Deprecated('Middleman role removed')
  static const String tableMiddlemanProfiles = 'middleman_profiles';

  // ==========================================================================
  // User Metadata Keys
  // ==========================================================================
  
  static const String keyAccountType = 'account_type';
  static const String keyFullName = 'full_name';
  static const String keyPhone = 'phone';
  static const String keyLocation = 'location';
  static const String keyCurrency = 'currency';
  static const String keyLanguage = 'language';
}
