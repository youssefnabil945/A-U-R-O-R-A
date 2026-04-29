import 'package:flutter/foundation.dart';

class ProductProvider {
  final String id;
  final String name;
  final String contactName;
  final String phoneNumber;
  final String email;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Provider analysis fields
  double totalSupplyValue;
  int totalSupplies;
  DateTime lastSupplyDate;
  String providerRating; // e.g., 'Preferred', 'Standard', 'New'
  List<String> suppliedProductIds;
  final List<String>? products;
  
  ProductProvider({
    required this.id,
    required this.name,
    required this.contactName,
    required this.phoneNumber,
    required this.email,
    this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.totalSupplyValue = 0.0,
    this.totalSupplies = 0,
    DateTime? lastSupplyDate,
    this.providerRating = 'New',
    List<String>? suppliedProductIds,
    this.products,
  }) : lastSupplyDate = lastSupplyDate ?? DateTime.now(),
       suppliedProductIds = suppliedProductIds ?? [];

  factory ProductProvider.fromMap(Map<String, dynamic> map) {
    return ProductProvider(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      contactName: map['contact_name'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      email: map['email'] ?? '',
      address: map['address'],
      notes: map['notes'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
      totalSupplyValue: (map['total_supply_value'] ?? 0).toDouble(),
      totalSupplies: map['total_supplies'] ?? 0,
      lastSupplyDate: map['last_supply_date'] != null
          ? DateTime.parse(map['last_supply_date'])
          : DateTime.now(),
      providerRating: map['provider_rating'] ?? 'New',
      suppliedProductIds: map['supplied_product_ids'] != null
          ? List<String>.from(map['supplied_product_ids'])
          : [],
      products: map['products'] != null
          ? List<String>.from(map['products'])
          : null,
    );
  }

  factory ProductProvider.fromJson(Map<String, dynamic> json) {
    return ProductProvider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      contactName: json['contactName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      address: json['address'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      totalSupplyValue: (json['totalSupplyValue'] ?? 0).toDouble(),
      totalSupplies: json['totalSupplies'] ?? 0,
      lastSupplyDate: json['lastSupplyDate'] != null
          ? DateTime.parse(json['lastSupplyDate'])
          : DateTime.now(),
      providerRating: json['providerRating'] ?? 'New',
      suppliedProductIds: json['suppliedProductIds'] != null
          ? List<String>.from(json['suppliedProductIds'])
          : [],
      products: json['products'] != null
          ? List<String>.from(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'total_supply_value': totalSupplyValue,
      'total_supplies': totalSupplies,
      'last_supply_date': lastSupplyDate.toIso8601String(),
      'provider_rating': providerRating,
      'supplied_product_ids': suppliedProductIds,
      'products': products,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'totalSupplyValue': totalSupplyValue,
      'totalSupplies': totalSupplies,
      'lastSupplyDate': lastSupplyDate.toIso8601String(),
      'providerRating': providerRating,
      'suppliedProductIds': suppliedProductIds,
      'products': products,
    };
  }

  ProductProvider copyWith({
    String? id,
    String? name,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalSupplyValue,
    int? totalSupplies,
    DateTime? lastSupplyDate,
    String? providerRating,
    List<String>? suppliedProductIds,
    List<String>? products,
  }) {
    return ProductProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalSupplyValue: totalSupplyValue ?? this.totalSupplyValue,
      totalSupplies: totalSupplies ?? this.totalSupplies,
      lastSupplyDate: lastSupplyDate ?? this.lastSupplyDate,
      providerRating: providerRating ?? this.providerRating,
      suppliedProductIds: suppliedProductIds ?? this.suppliedProductIds,
      products: products ?? this.products,
    );
  }
}
