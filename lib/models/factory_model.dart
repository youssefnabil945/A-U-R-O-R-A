import 'package:flutter/foundation.dart';

class FactoryModel {
  final String id;
  final String name;
  final String email;
  final String? location;
  final String? specialization;
  final int? productionCapacity;
  final DateTime createdAt;
  final List<String>? certifications;
  final String? description;
  final String? website;
  final List<String>? products;
  
  FactoryModel({
    required this.id,
    required this.name,
    required this.email,
    this.location,
    this.specialization,
    this.productionCapacity,
    required this.createdAt,
    this.certifications,
    this.description,
    this.website,
    this.products,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'location': location,
      'specialization': specialization,
      'production_capacity': productionCapacity,
      'created_at': createdAt.toIso8601String(),
      'certifications': certifications,
      'description': description,
      'website': website,
      'products': products,
    };
  }

  factory FactoryModel.fromMap(Map<String, dynamic> map) {
    return FactoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      location: map['location'],
      specialization: map['specialization'],
      productionCapacity: map['production_capacity'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      certifications: map['certifications'] != null
          ? List<String>.from(map['certifications'])
          : null,
      description: map['description'],
      website: map['website'],
      products: map['products'] != null
          ? List<String>.from(map['products'])
          : null,
    );
  }

  factory FactoryModel.fromJson(Map<String, dynamic> json) {
    return FactoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      location: json['location'],
      specialization: json['specialization'],
      productionCapacity: json['production_capacity'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : null,
      description: json['description'],
      website: json['website'],
      products: json['products'] != null
          ? List<String>.from(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  FactoryModel copyWith({
    String? id,
    String? name,
    String? email,
    String? location,
    String? specialization,
    int? productionCapacity,
    DateTime? createdAt,
    List<String>? certifications,
    String? description,
    String? website,
    List<String>? products,
  }) {
    return FactoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      location: location ?? this.location,
      specialization: specialization ?? this.specialization,
      productionCapacity: productionCapacity ?? this.productionCapacity,
      createdAt: createdAt ?? this.createdAt,
      certifications: certifications ?? this.certifications,
      description: description ?? this.description,
      website: website ?? this.website,
      products: products ?? this.products,
    );
  }
}
