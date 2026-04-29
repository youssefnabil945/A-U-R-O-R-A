import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/aurora_product.dart';
import '../models/raw_material.dart';

/// **Factory Materials Database Service**
///
/// Manages raw material inventory for factory accounts.
/// Tracks stock levels, costs, and units for production planning.
///
/// Storage Structure:
/// {seller_uuid}/factory/materials.json
class FactoryMaterialsDB {
  static final FactoryMaterialsDB _instance = FactoryMaterialsDB._internal();
  factory FactoryMaterialsDB() => _instance;
  FactoryMaterialsDB._internal();

  String? _currentSellerUuid;

  /// Set the current seller UUID (call after login)
  void setSellerUuid(String uuid) {
    _currentSellerUuid = uuid;
  }

  /// Get the materials file path
  Future<File> _getMaterialsFile() async {
    if (_currentSellerUuid == null) {
      throw Exception('Seller UUID not set. Call setSellerUuid() first.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final sellerDir = Directory('${directory.path}/${_currentSellerUuid}/factory');
    
    if (!await sellerDir.exists()) {
      await sellerDir.create(recursive: true);
    }

    return File('${sellerDir.path}/materials.json');
  }

  /// Get all raw materials
  Future<List<RawMaterial>> getAllMaterials() async {
    try {
      final file = await _getMaterialsFile();
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((e) => RawMaterial.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading materials: $e');
      return [];
    }
  }

  /// Save a new raw material or update existing one
  Future<RawMaterial> saveMaterial(RawMaterial material) async {
    final materials = await getAllMaterials();

    // Check if exists, update if so
    final index = materials.indexWhere((m) => m.id == material.id);

    RawMaterial savedMaterial;
    if (index != -1) {
      // Update existing
      materials[index] = material;
      savedMaterial = material;
    } else {
      // Add new
      materials.add(material);
      savedMaterial = material;
    }

    // Save to file
    final file = await _getMaterialsFile();
    final jsonList = materials.map((m) => m.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));

    return savedMaterial;
  }

  /// Delete a raw material
  Future<bool> deleteMaterial(String materialId) async {
    final materials = await getAllMaterials();
    final removed = materials.removeWhere((m) => m.id == materialId);

    if (removed) {
      final file = await _getMaterialsFile();
      final jsonList = materials.map((m) => m.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
      return true;
    }

    return false;
  }

  /// Get low stock materials (below threshold)
  Future<List<RawMaterial>> getLowStockMaterials({double threshold = 0.2}) async {
    final materials = await getAllMaterials();
    return materials.where((m) {
      if (m.minStock == null || m.currentStock == null) return false;
      return m.currentStock! < (m.minStock! * threshold);
    }).toList();
  }

  /// Update material stock
  Future<RawMaterial?> updateStock(String materialId, double quantityChange) async {
    final materials = await getAllMaterials();
    final index = materials.indexWhere((m) => m.id == materialId);

    if (index == -1) return null;

    final material = materials[index];
    final newStock = (material.currentStock ?? 0) + quantityChange;
    
    if (newStock < 0) {
      throw Exception('Cannot reduce stock below zero');
    }

    final updated = material.copyWith(currentStock: newStock);
    materials[index] = updated;

    final file = await _getMaterialsFile();
    final jsonList = materials.map((m) => m.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));

    return updated;
  }

  /// Clear all materials (for testing or reset)
  Future<void> clearAll() async {
    try {
      final file = await _getMaterialsFile();
      if (await file.exists()) {
        await file.writeAsString('[]');
      }
    } catch (e) {
      debugPrint('Error clearing materials: $e');
    }
  }
}
