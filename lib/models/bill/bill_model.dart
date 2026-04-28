import 'package:equatable/equatable.dart';

enum BillType {
  standard,
  proforma,
  commercial,
}

enum BillStatus {
  draft,
  pending,
  paid,
  overdue,
  cancelled,
}

class BillModel extends Equatable {
  final String id;
  final String sellerId;
  final BillType type;
  final BillRecipient recipient;
  final List<BillItem> items;
  final double totalAmount;
  final String currency;
  final String? notes;
  final BillStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? pdfUrl;

  const BillModel({
    required this.id,
    required this.sellerId,
    required this.type,
    required this.recipient,
    required this.items,
    required this.totalAmount,
    this.currency = 'USD',
    this.notes,
    this.status = BillStatus.draft,
    required this.createdAt,
    this.dueDate,
    this.paidAt,
    this.pdfUrl,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      type: BillType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BillType.standard,
      ),
      recipient: BillRecipient.fromJson(json['recipient'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      notes: json['notes'] as String?,
      status: BillStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BillStatus.draft,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      pdfUrl: json['pdf_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'type': type.name,
      'recipient': recipient.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'currency': currency,
      'notes': notes,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'pdf_url': pdfUrl,
    };
  }

  BillModel copyWith({
    String? id,
    String? sellerId,
    BillType? type,
    BillRecipient? recipient,
    List<BillItem>? items,
    double? totalAmount,
    String? currency,
    String? notes,
    BillStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? paidAt,
    String? pdfUrl,
  }) {
    return BillModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      type: type ?? this.type,
      recipient: recipient ?? this.recipient,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sellerId,
        type,
        recipient,
        items,
        totalAmount,
        currency,
        notes,
        status,
        createdAt,
        dueDate,
        paidAt,
        pdfUrl,
      ];
}

class BillRecipient extends Equatable {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? company;
  final String? taxId;

  const BillRecipient({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.company,
    this.taxId,
  });

  const BillRecipient.empty()
      : name = '',
        email = '',
        phone = '',
        address = '',
        company = null,
        taxId = null;

  factory BillRecipient.fromJson(Map<String, dynamic> json) {
    return BillRecipient(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      company: json['company'] as String?,
      taxId: json['tax_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'company': company,
      'tax_id': taxId,
    };
  }

  bool isValid() {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty &&
        address.isNotEmpty;
  }

  void updateFrom(BillRecipient other) {
    // This is immutable, so we can't update. Use copyWith instead.
  }

  BillRecipient copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? company,
    String? taxId,
  }) {
    return BillRecipient(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      company: company ?? this.company,
      taxId: taxId ?? this.taxId,
    );
  }

  @override
  List<Object?> get props => [name, email, phone, address, company, taxId];
}

class BillItem extends Equatable {
  final String id;
  final String productId;
  final String description;
  final double quantity;
  final double price;
  final double? discount;

  const BillItem({
    required this.id,
    required this.productId,
    required this.description,
    required this.quantity,
    required this.price,
    this.discount,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'description': description,
      'quantity': quantity,
      'price': price,
      'discount': discount,
    };
  }

  double get subtotal => (quantity * price) - (discount ?? 0);

  BillItem copyWith({
    String? id,
    String? productId,
    String? description,
    double? quantity,
    double? price,
    double? discount,
  }) {
    return BillItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
    );
  }

  @override
  List<Object?> get props => [id, productId, description, quantity, price, discount];
}
