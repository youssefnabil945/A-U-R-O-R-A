// ============================================================================
// Supabase Enums
// ============================================================================
// 
// Enumerations used across Supabase operations.
// ============================================================================

/// Represents the type of user account in the Aurora system
enum AccountType {
  seller,      // Seller/merchant
  factory,     // Factory/manufacturer
  customer,    // Customer/buyer
}

/// Order Status
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

/// Notification Type
enum NotificationType {
  order,
  product,
  system,
  promotion,
  message,
}
