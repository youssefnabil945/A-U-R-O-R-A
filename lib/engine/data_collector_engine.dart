import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../models/product_provider.dart';
import '../models/aurora_customer.dart';
import 'analysis_engine.dart';
import '../services/supabase.dart';

/// **Data Collector Engine**
/// 
/// This engine acts as the central aggregator. It collects:
/// 1. All Customers
/// 2. All Bills (Invoices)
/// 3. All Product Providers
/// 
/// It processes them through the [AnalysisEngine], then compiles everything
/// into a single JSON file stored in a UUID-named folder.
/// 
/// **Storage Path:** `/app_documents/{uuid}/{username}.json`
class DataCollectorEngine {
  final SupabaseProvider _db;
  final AnalysisEngine _analysisEngine;
  final Uuid _uuid;

  DataCollectorEngine({
    SupabaseProvider? db,
    required List<Customer> customers,
    required List<Bill> bills,
    required List<ProductProvider> providers,
    AnalysisEngine? analysisEngine,
  })  : _db = db ?? SupabaseProvider(),
        _analysisEngine = analysisEngine ?? AnalysisEngine(
          customers: customers.map((c) => AuroraCustomer(
            id: c.id,
            name: c.name,
            phoneNumber: c.phoneNumber ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )).toList(),
          bills: bills,
          providers: providers,
        ),
        _uuid = const Uuid();

  /// The result structure that will be saved to JSON
  Map<String, dynamic> _compileData({
    required List<Customer> customers,
    required List<Bill> bills,
    required List<ProductProvider> providers,
    required Map<String, dynamic> kpiData,
    required String username,
    required DateTime generatedAt,
  }) {
    return {
      'meta': {
        'username': username,
        'generated_at': generatedAt.toIso8601String(),
        'version': '1.0.0',
        'seller_id': _db.currentUserId, // Assuming SupabaseService exposes this
      },
      'summary_kpi': kpiData,
      'customers': customers.map((c) => c.toJson()).toList(),
      'bills': bills.map((b) => b.toJson()).toList(),
      'providers': providers.map((p) => p.toJson()).toList(),
    };
  }

  /// **Main Collection Method**
  /// 
  /// 1. Fetches raw data from DB.
  /// 2. Runs Analysis.
  /// 3. Creates UUID folder.
  /// 4. Saves combined JSON file.
  Future<Map<String, dynamic>> collectAndSaveAllData({
    required String username,
    required List<Customer> customers,
    required List<Bill> bills,
    required List<ProductProvider> providers,
  }) async {
    print('🚀 Starting Data Collection Engine...');

    // 1. Use provided data (already fetched)
    print('📦 Processing: ${customers.length} Customers, ${bills.length} Bills, ${providers.length} Providers');

    // 2. Run Analysis Engine to get KPIs
    final analysisEngine = AnalysisEngine(
      customers: customers.map((c) => AuroraCustomer(
        id: c.id,
        name: c.name,
        phoneNumber: c.phoneNumber ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList(),
      bills: bills,
      providers: providers,
    );
    
    final kpiData = _generateFullAnalysis(
      customers: customers,
      bills: bills,
      providers: providers,
    );

    // 3. Compile Data
    final compiledData = _compileData(
      customers: customers,
      bills: bills,
      providers: providers,
      kpiData: kpiData,
      username: username,
      generatedAt: DateTime.now(),
    );

    // 4. Generate UUID for the folder
    final sessionId = _uuid.v4();
    
    // 5. Save to File System
    final filePath = await _saveToFile(
      data: compiledData,
      folderName: sessionId,
      fileName: '$username.json',
    );

    print('✅ Data successfully saved to: $filePath');
    
    return {
      'status': 'success',
      'path': filePath,
      'folder_id': sessionId,
      'data': compiledData,
    };
  }

  /// Generate full analysis KPI data
  Map<String, dynamic> _generateFullAnalysis({
    required List<Customer> customers,
    required List<Bill> bills,
    required List<ProductProvider> providers,
  }) {
    double totalRevenue = bills.fold(0.0, (sum, bill) => sum + bill.total);
    int totalOrders = bills.length;
    int totalCustomers = customers.length;
    double averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    
    return {
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'total_customers': totalCustomers,
      'average_order_value': averageOrderValue,
      'total_providers': providers.length,
    };
  }

  /// Handles the physical file creation in the app's documents directory
  Future<String> _saveToFile({
    required Map<String, dynamic> data,
    required String folderName,
    required String fileName,
  }) async {
    // Get the application documents directory
    final Directory appDir = await getApplicationDocumentsDirectory();
    
    // Create the UUID folder: /documents/{uuid}/
    final Directory targetFolder = Directory('${appDir.path}/$folderName');
    
    if (!await targetFolder.exists()) {
      await targetFolder.create(recursive: true);
    }

    // Create the file path: /documents/{uuid}/{username}.json
    final File targetFile = File('${targetFolder.path}/$fileName');

    // Convert to pretty JSON
    final String jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Write to file
    await targetFile.writeAsString(jsonString);

    return targetFile.path;
  }

  /// **Load Data from Specific UUID Folder**
  /// 
  /// Allows retrieving the saved master file if you know the UUID and username.
  Future<Map<String, dynamic>?> loadDataFromFolder({
    required String folderId,
    required String username,
  }) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final File targetFile = File('${appDir.path}/$folderId/$username.json');

      if (!await targetFile.exists()) {
        print('⚠️ File not found: $folderId/$username.json');
        return null;
      }

      final String content = await targetFile.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error loading data: $e');
      return null;
    }
  }

  /// **List All Available Collection Folders**
  /// 
  /// Scans the documents directory to find all UUID folders created by this engine.
  Future<List<Map<String, String>>> listAvailableCollections() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final List<Map<String, String>> collections = [];

    if (!await appDir.exists()) return collections;

    await for (final entity in appDir.list()) {
      if (entity is Directory) {
        final dirName = entity.uri.pathSegments.last;
        // Simple validation: check if it looks like a UUID (basic check)
        // Or just assume all subdirs are collections
        final fileList = await entity.list().toList();
        final jsonFiles = fileList.whereType<File>().where((f) => f.path.endsWith('.json')).toList();
        
        for (var file in jsonFiles) {
          collections.add({
            'folder_id': dirName,
            'filename': file.uri.pathSegments.last,
            'path': file.path,
            'last_modified': await file.lastModified().then((d) => d.toIso8601String()),
          });
        }
      }
    }
    return collections;
  }
}
