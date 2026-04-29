/// Model representing a connection between a seller and a factory
/// 
/// This model facilitates the B2B relationship where sellers can discover,
/// connect with, and exchange products from factories.
class SellerFactoryConnection {
  final String id;
  final String factoryId;
  final String factoryName;
  final String sellerId;
  final String sellerName;
  final ConnectionStatus status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? notes;
  final List<String> exchangedProductIds;
  final int totalDeals;
  final double totalVolume;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellerFactoryConnection({
    required this.id,
    required this.factoryId,
    required this.factoryName,
    required this.sellerId,
    required this.sellerName,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.notes,
    this.exchangedProductIds = const [],
    this.totalDeals = 0,
    this.totalVolume = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON map
  factory SellerFactoryConnection.fromJson(Map<String, dynamic> json) {
    return SellerFactoryConnection(
      id: json['id'] as String,
      factoryId: json['factory_id'] as String,
      factoryName: json['factory_name'] as String? ?? '',
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String? ?? '',
      status: ConnectionStatus.fromString(json['status'] as String? ?? 'pending'),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      notes: json['notes'] as String?,
      exchangedProductIds: (json['exchanged_product_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalDeals: json['total_deals'] as int? ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'factory_id': factoryId,
      'factory_name': factoryName,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'status': status.toString().split('.').last,
      'requested_at': requestedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'notes': notes,
      'exchanged_product_ids': exchangedProductIds,
      'total_deals': totalDeals,
      'total_volume': totalVolume,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if connection is pending
  bool get isPending => status == ConnectionStatus.pending;

  /// Check if connection is accepted
  bool get isAccepted => status == ConnectionStatus.accepted;

  /// Check if connection is rejected
  bool get isRejected => status == ConnectionStatus.rejected;

  /// Check if connection is blocked
  bool get isBlocked => status == ConnectionStatus.blocked;

  /// Get connection duration in days
  int get connectionDurationDays {
    if (acceptedAt == null) return 0;
    return DateTime.now().difference(acceptedAt!).inDays;
  }

  /// Copy with method for immutability
  SellerFactoryConnection copyWith({
    String? id,
    String? factoryId,
    String? factoryName,
    String? sellerId,
    String? sellerName,
    ConnectionStatus? status,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? notes,
    List<String>? exchangedProductIds,
    int? totalDeals,
    double? totalVolume,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerFactoryConnection(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      factoryName: factoryName ?? this.factoryName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      notes: notes ?? this.notes,
      exchangedProductIds: exchangedProductIds ?? this.exchangedProductIds,
      totalDeals: totalDeals ?? this.totalDeals,
      totalVolume: totalVolume ?? this.totalVolume,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SellerFactoryConnection(id: $id, factory: $factoryName, seller: $sellerName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SellerFactoryConnection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Status of a seller-factory connection
enum ConnectionStatus {
  pending, // Connection request sent, awaiting acceptance
  accepted, // Connection established
  rejected, // Connection request rejected
  blocked, // Connection blocked by either party
}

extension ConnectionStatusExtension on ConnectionStatus {
  static ConnectionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return ConnectionStatus.pending;
      case 'accepted':
        return ConnectionStatus.accepted;
      case 'rejected':
        return ConnectionStatus.rejected;
      case 'blocked':
        return ConnectionStatus.blocked;
      default:
        return ConnectionStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case ConnectionStatus.pending:
        return 'Pending';
      case ConnectionStatus.accepted:
        return 'Connected';
      case ConnectionStatus.rejected:
        return 'Rejected';
      case ConnectionStatus.blocked:
        return 'Blocked';
    }
  }
}

/// Model representing a product exchange between seller and factory
class ProductExchange {
  final String id;
  final String connectionId;
  final String productId;
  final String productName;
  final String fromPartyId; // Factory or Seller ID
  final String toPartyId; // Seller or Factory ID
  final ExchangeType exchangeType;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final ExchangeStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  ProductExchange({
    required this.id,
    required this.connectionId,
    required this.productId,
    required this.productName,
    required this.fromPartyId,
    required this.toPartyId,
    required this.exchangeType,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  /// Create from JSON map
  factory ProductExchange.fromJson(Map<String, dynamic> json) {
    return ProductExchange(
      id: json['id'] as String,
      connectionId: json['connection_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      fromPartyId: json['from_party_id'] as String,
      toPartyId: json['to_party_id'] as String,
      exchangeType: ExchangeType.fromString(json['exchange_type'] as String? ?? 'wholesale'),
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      status: ExchangeStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connection_id': connectionId,
      'product_id': productId,
      'product_name': productName,
      'from_party_id': fromPartyId,
      'to_party_id': toPartyId,
      'exchange_type': exchangeType.toString().split('.').last,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Copy with method
  ProductExchange copyWith({
    String? id,
    String? connectionId,
    String? productId,
    String? productName,
    String? fromPartyId,
    String? toPartyId,
    ExchangeType? exchangeType,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
    ExchangeStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ProductExchange(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      fromPartyId: fromPartyId ?? this.fromPartyId,
      toPartyId: toPartyId ?? this.toPartyId,
      exchangeType: exchangeType ?? this.exchangeType,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'ProductExchange(id: $id, product: $productName, quantity: $quantity, status: $status)';
  }
}

/// Type of product exchange
enum ExchangeType {
  wholesale, // Factory selling to seller in bulk
  consignment, // Factory placing products on consignment
  dropshipping, // Factory shipping directly to customer
  customOrder, // Custom manufacturing order
}

extension ExchangeTypeExtension on ExchangeType {
  static ExchangeType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'wholesale':
        return ExchangeType.wholesale;
      case 'consignment':
        return ExchangeType.consignment;
      case 'dropshipping':
        return ExchangeType.dropshipping;
      case 'custom_order':
        return ExchangeType.customOrder;
      default:
        return ExchangeType.wholesale;
    }
  }

  String get displayName {
    switch (this) {
      case ExchangeType.wholesale:
        return 'Wholesale';
      case ExchangeType.consignment:
        return 'Consignment';
      case ExchangeType.dropshipping:
        return 'Dropshipping';
      case ExchangeType.customOrder:
        return 'Custom Order';
    }
  }
}

/// Status of a product exchange
enum ExchangeStatus {
  pending, // Exchange proposed
  confirmed, // Exchange confirmed by both parties
  inProgress, // Exchange in progress
  completed, // Exchange completed
  cancelled, // Exchange cancelled
}

extension ExchangeStatusExtension on ExchangeStatus {
  static ExchangeStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return ExchangeStatus.pending;
      case 'confirmed':
        return ExchangeStatus.confirmed;
      case 'in_progress':
        return ExchangeStatus.inProgress;
      case 'completed':
        return ExchangeStatus.completed;
      case 'cancelled':
        return ExchangeStatus.cancelled;
      default:
        return ExchangeStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case ExchangeStatus.pending:
        return 'Pending';
      case ExchangeStatus.confirmed:
        return 'Confirmed';
      case ExchangeStatus.inProgress:
        return 'In Progress';
      case ExchangeStatus.completed:
        return 'Completed';
      case ExchangeStatus.cancelled:
        return 'Cancelled';
    }
  }
}
