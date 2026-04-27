import 'dart:convert';

/// **Bill Model**
/// 
/// Represents a wholesale bill shared between Factory and Seller.
/// This model is used for offline sharing via encrypted files.
class BillModel {
  final String billId;
  final String factoryUuid;
  final String sellerUuid;
  final DateTime timestamp;
  final List<BillItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String? notes;
  final String currency;

  BillModel({
    required this.billId,
    required this.factoryUuid,
    required this.sellerUuid,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    this.notes,
    this.currency = 'USD',
  });

  /// Create from JSON map
  factory BillModel.fromJson(Map<String, dynamic> json) {
    final header = json['header'] as Map<String, dynamic>;
    final summary = json['summary'] as Map<String, dynamic>;
    final itemsJson = json['items'] as List<dynamic>;

    return BillModel(
      billId: header['billId'] as String,
      factoryUuid: header['factoryUuid'] as String,
      sellerUuid: header['sellerUuid'] as String,
      timestamp: DateTime.parse(header['timestamp'] as String),
      items: itemsJson.map((item) => BillItem.fromJson(item)).toList(),
      totalAmount: (summary['totalAmount'] as num).toDouble(),
      paymentMethod: header['paymentMethod'] as String,
      notes: header['notes'] as String?,
      currency: summary['currency'] as String? ?? 'USD',
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'header': {
        'type': 'OFFLINE_BILL',
        'version': '1.0',
        'billId': billId,
        'timestamp': timestamp.toIso8601String(),
        'factoryUuid': factoryUuid,
        'sellerUuid': sellerUuid,
        'paymentMethod': paymentMethod,
        'notes': notes ?? '',
      },
      'items': items.map((item) => item.toJson()).toList(),
      'summary': {
        'itemCount': items.length,
        'totalAmount': totalAmount,
        'currency': currency,
      }
    };
  }

  /// Create a copy with updated fields
  BillModel copyWith({
    String? billId,
    String? factoryUuid,
    String? sellerUuid,
    DateTime? timestamp,
    List<BillItem>? items,
    double? totalAmount,
    String? paymentMethod,
    String? notes,
    String? currency,
  }) {
    return BillModel(
      billId: billId ?? this.billId,
      factoryUuid: factoryUuid ?? this.factoryUuid,
      sellerUuid: sellerUuid ?? this.sellerUuid,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
    );
  }
}

/// **Bill Item**
/// 
/// Represents a single product line item in a bill.
class BillItem {
  final String productId;
  final String productName;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  BillItem({
    required this.productId,
    required this.productName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Create from JSON map
  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      sku: json['sku'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  /// Calculate total price automatically
  factory BillItem.calculate({
    required String productId,
    required String productName,
    String? sku,
    required int quantity,
    required double unitPrice,
  }) {
    return BillItem(
      productId: productId,
      productName: productName,
      sku: sku,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: unitPrice * quantity,
    );
  }
}

/// **Import Record**
/// 
/// Tracks imported bills in the Seller's local database.
/// This is what gets stored in the "imports" JSON section.
class ImportRecord {
  final String importId;
  final String billId;
  final String factoryUuid;
  final String factoryName;
  final DateTime importDate;
  final DateTime billDate;
  final double totalAmount;
  final int itemCount;
  final String status; // 'pending', 'processed', 'rejected'
  final String? localFilePath;

  ImportRecord({
    required this.importId,
    required this.billId,
    required this.factoryUuid,
    required this.factoryName,
    required this.importDate,
    required this.billDate,
    required this.totalAmount,
    required this.itemCount,
    this.status = 'pending',
    this.localFilePath,
  });

  /// Create from JSON map
  factory ImportRecord.fromJson(Map<String, dynamic> json) {
    return ImportRecord(
      importId: json['importId'] as String,
      billId: json['billId'] as String,
      factoryUuid: json['factoryUuid'] as String,
      factoryName: json['factoryName'] as String,
      importDate: DateTime.parse(json['importDate'] as String),
      billDate: DateTime.parse(json['billDate'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      itemCount: json['itemCount'] as int,
      status: json['status'] as String? ?? 'pending',
      localFilePath: json['localFilePath'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'importId': importId,
      'billId': billId,
      'factoryUuid': factoryUuid,
      'factoryName': factoryName,
      'importDate': importDate.toIso8601String(),
      'billDate': billDate.toIso8601String(),
      'totalAmount': totalAmount,
      'itemCount': itemCount,
      'status': status,
      'localFilePath': localFilePath,
    };
  }
}
