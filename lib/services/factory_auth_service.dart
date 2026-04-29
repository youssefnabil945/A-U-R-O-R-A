import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/factory.dart';
import '../services/secure_storage_service.dart';

/// Authentication service specifically for Factory accounts
class FactoryAuthService {
  static final FactoryAuthService _instance = FactoryAuthService._internal();
  factory FactoryAuthService() => _instance;
  FactoryAuthService._internal();

  Factory? _currentFactory;
  final SecureStorageService _storage = SecureStorageService();

  /// Get current logged in factory
  Factory? get currentFactory => _currentFactory;

  /// Check if factory is logged in
  bool get isLoggedIn => _currentFactory != null;

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    try {
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      
      // Find factory by username (in production, this would be a database query)
      final directory = await getApplicationDocumentsDirectory();
      final factoryFile = File('${directory.path}/secure_storage/factories/$username.json');
      
      if (!await factoryFile.exists()) {
        debugPrint('Factory not found: $username');
        return false;
      }
      
      final content = await factoryFile.readAsString();
      final Map<String, dynamic> factoryData = json.decode(content);
      
      if (factoryData['password'] != hashedPassword) {
        debugPrint('Invalid password for: $username');
        return false;
      }
      
      _currentFactory = Factory.fromMap(factoryData);
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// Register new factory
  Future<Factory?> register({
    required String username,
    required String password,
    required String name,
    String? location,
    String? specialization,
    int? productionCapacity,
  }) async {
    try {
      // Check if factory already exists
      final existing = await _getFactoryByUsername(username);
      if (existing != null) {
        debugPrint('Factory already exists: $username');
        return null;
      }
      
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      final uuid = DateTime.now().millisecondsSinceEpoch.toString();
      
      final factory = Factory(
        id: uuid,
        username: username,
        password: hashedPassword,
        name: name,
        location: location,
        specialization: specialization,
        productionCapacity: productionCapacity,
        createdAt: DateTime.now(),
      );
      
      // Save to secure storage
      final success = await _saveFactory(factory);
      
      if (success) {
        _currentFactory = factory;
        await _saveFactoryToIndex(uuid, username);
      }
      
      return success ? factory : null;
    } catch (e) {
      debugPrint('Registration error: $e');
      return null;
    }
  }

  /// Logout current factory
  Future<void> logout() async {
    _currentFactory = null;
  }

  /// Get factory by username
  Future<Factory?> _getFactoryByUsername(String username) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final factoryFile = File('${directory.path}/secure_storage/factories/$username.json');
      
      if (!await factoryFile.exists()) {
        return null;
      }
      
      final content = await factoryFile.readAsString();
      final Map<String, dynamic> factoryData = json.decode(content);
      
      return Factory.fromMap(factoryData);
    } catch (e) {
      debugPrint('Get factory error: $e');
      return null;
    }
  }

  /// Save factory to secure storage
  Future<bool> _saveFactory(Factory factory) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final factoriesDir = Directory('${directory.path}/secure_storage/factories');
      
      if (!await factoriesDir.exists()) {
        await factoriesDir.create(recursive: true);
      }
      
      final factoryFile = File('${factoriesDir.path}/${factory.username}.json');
      await factoryFile.writeAsString(json.encode(factory.toMap()));
      
      return true;
    } catch (e) {
      debugPrint('Save factory error: $e');
      return false;
    }
  }

  /// Helper: Get index of all factories (username -> UUID mapping)
  Future<Map<String, String>> _getAllFactoriesIndex() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final indexFile = File('${directory.path}/secure_storage/factories_index.json');

      if (!await indexFile.exists()) {
        return {};
      }

      final content = await indexFile.readAsString();
      if (content.isEmpty) {
        return {};
      }

      return Map<String, String>.from(json.decode(content));
    } catch (e) {
      debugPrint('Error loading factories index: $e');
      return {};
    }
  }

  /// Helper: Save factory to index
  Future<void> _saveFactoryToIndex(String uuid, String username) async {
    try {
      final index = await _getAllFactoriesIndex();
      index[uuid] = username;

      final directory = await getApplicationDocumentsDirectory();
      final indexFile = File('${directory.path}/secure_storage/factories_index.json');

      if (!await indexFile.parent.exists()) {
        await indexFile.parent.create(recursive: true);
      }

      await indexFile.writeAsString(json.encode(index));
    } catch (e) {
      debugPrint('Error saving factory to index: $e');
    }
  }

  /// Export factory data as JSON string
  Future<String?> exportFactoryData() async {
    if (_currentFactory == null) return null;
    
    try {
      return json.encode(_currentFactory!.toMap());
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  /// Import factory data from JSON string
  Future<bool> importFactoryData(String jsonData) async {
    try {
      final Map<String, dynamic> factoryData = json.decode(jsonData);
      _currentFactory = Factory.fromMap(factoryData);
      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }
}
