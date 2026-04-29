import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/factory_model.dart';

/// FactoryStorageService handles local storage of factory data
class FactoryStorageService {
  static const String _factoryFileName = 'factory_data.json';
  
  /// Get the directory for storing factory data
  Future<Directory> _getStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${appDir.path}/factory_storage');
    
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    
    return storageDir;
  }
  
  /// Get the path to the factory data file
  Future<String> _getFactoryFilePath() async {
    final storageDir = await _getStorageDirectory();
    return '${storageDir.path}/$_factoryFileName';
  }
  
  /// Save factory data to local storage
  Future<void> saveFactoryData(FactoryModel factory) async {
    try {
      final filePath = await _getFactoryFilePath();
      final file = File(filePath);
      
      final jsonData = jsonEncode(factory.toJson());
      await file.writeAsString(jsonData);
    } catch (e) {
      throw Exception('Failed to save factory data: $e');
    }
  }
  
  /// Load factory data from local storage
  Future<FactoryModel?> loadFactoryData() async {
    try {
      final filePath = await _getFactoryFilePath();
      final file = File(filePath);
      
      if (!await file.exists()) {
        return null;
      }
      
      final jsonData = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonData);
      
      return FactoryModel.fromJson(jsonMap);
    } catch (e) {
      // If there's an error reading the file, return null
      return null;
    }
  }
  
  /// Delete factory data from local storage
  Future<void> deleteFactoryData() async {
    try {
      final filePath = await _getFactoryFilePath();
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete factory data: $e');
    }
  }
  
  /// Check if factory data exists
  Future<bool> hasFactoryData() async {
    try {
      final filePath = await _getFactoryFilePath();
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// Clear all factory storage
  Future<void> clearAllStorage() async {
    try {
      final storageDir = await _getStorageDirectory();
      if (await storageDir.exists()) {
        await storageDir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to clear factory storage: $e');
    }
  }
}
