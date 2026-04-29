/// Service for managing connections between sellers and factories
/// 
/// This service handles:
/// - Creating connection requests
/// - Accepting/rejecting connections
/// - Managing product exchanges
/// - Tracking deal history
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/seller_factory_connection.dart';
import '../services/error_handler.dart';

/// Manages seller-factory connections and product exchanges
class SellerFactoryConnectionService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final ErrorHandler _errorHandler;
  
  List<SellerFactoryConnection> _connections = [];
  List<ProductExchange> _exchanges = [];
  bool _isLoading = false;
  String? _currentUserId;

  SellerFactoryConnectionService({required SupabaseClient supabase})
      : _supabase = supabase,
        _errorHandler = ErrorHandler() {
    _init();
  }

  /// Initialize the service
  Future<void> _init() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _currentUserId = user.id;
        await loadConnections();
      }
      
      // Listen for auth changes
      _supabase.auth.onAuthStateChange.listen((data) {
        _currentUserId = data.session?.user.id;
        if (_currentUserId != null) {
          loadConnections();
        } else {
          _connections.clear();
          _exchanges.clear();
          notifyListeners();
        }
      });
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'init', stackTrace: stackTrace);
    }
  }

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Get all connections
  List<SellerFactoryConnection> get connections => List.unmodifiable(_connections);

  /// Get pending connections
  List<SellerFactoryConnection> get pendingConnections =>
      _connections.where((c) => c.isPending).toList();

  /// Get accepted connections
  List<SellerFactoryConnection> get acceptedConnections =>
      _connections.where((c) => c.isAccepted).toList();

  /// Get all exchanges
  List<ProductExchange> get exchanges => List.unmodifiable(_exchanges);

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Load connections for current user
  Future<void> loadConnections() async {
    if (_currentUserId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('factory_connections')
          .select('''
            id,
            factory_id,
            seller_id,
            status,
            requested_at,
            accepted_at,
            rejected_at,
            notes,
            created_at,
            updated_at,
            factories:sellers!factory_id(
              full_name,
              factory_name
            ),
            sellers:sellers!seller_id(
              full_name
            )
          ''')
          .or('factory_id.eq.$_currentUserId,seller_id.eq.$_currentUserId');

      _connections = (response.data as List)
          .map((item) => _parseConnection(item))
          .toList();

      // Load exchanges for these connections
      await _loadExchanges();
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'loadConnections', stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Parse connection from Supabase response
  SellerFactoryConnection _parseConnection(Map<String, dynamic> item) {
    final factoryData = item['factories'] as Map<String, dynamic>? ?? {};
    final sellerData = item['sellers'] as Map<String, dynamic>? ?? {};
    
    return SellerFactoryConnection(
      id: item['id'] as String,
      factoryId: item['factory_id'] as String,
      factoryName: factoryData['factory_name'] as String? ?? 
                   factoryData['full_name'] as String? ?? '',
      sellerId: item['seller_id'] as String,
      sellerName: sellerData['full_name'] as String? ?? '',
      status: ConnectionStatus.fromString(item['status'] as String? ?? 'pending'),
      requestedAt: DateTime.parse(item['requested_at'] as String),
      acceptedAt: item['accepted_at'] != null
          ? DateTime.parse(item['accepted_at'] as String)
          : null,
      rejectedAt: item['rejected_at'] != null
          ? DateTime.parse(item['rejected_at'] as String)
          : null,
      notes: item['notes'] as String?,
      createdAt: DateTime.parse(item['created_at'] as String),
      updatedAt: DateTime.parse(item['updated_at'] as String),
    );
  }

  /// Load exchanges for current connections
  Future<void> _loadExchanges() async {
    if (_connections.isEmpty) {
      _exchanges.clear();
      return;
    }

    try {
      final connectionIds = _connections.map((c) => c.id).toList();
      
      final response = await _supabase
          .from('product_exchanges')
          .select('*')
          .inFilter('connection_id', connectionIds);

      _exchanges = (response.data as List)
          .map((item) => ProductExchange.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, '_loadExchanges', stackTrace: stackTrace);
    }
  }

  /// Request a connection with a factory
  /// 
  /// [factoryId] - The factory user ID to connect with
  /// [notes] - Optional message to include with the request
  Future<SellerFactoryConnection?> requestConnection({
    required String factoryId,
    String? notes,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated');
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.from('factory_connections').insert({
        'factory_id': factoryId,
        'seller_id': _currentUserId,
        'status': 'pending',
        'notes': notes,
      }).select().single();

      final connection = _parseConnection(response.data);
      _connections.add(connection);
      notifyListeners();
      
      debugPrint('[SellerFactoryConnection] Requested connection with factory: $factoryId');
      return connection;
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'requestConnection', 
        context: {'factory_id': factoryId},
        stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Accept a connection request (called by factory)
  Future<bool> acceptConnection(String connectionId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('factory_connections')
          .update({
            'status': 'accepted',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId)
          .select()
          .single();

      // Update local connection
      final index = _connections.indexWhere((c) => c.id == connectionId);
      if (index != -1) {
        _connections[index] = _parseConnection(response.data);
      }

      notifyListeners();
      debugPrint('[SellerFactoryConnection] Accepted connection: $connectionId');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'acceptConnection',
        context: {'connection_id': connectionId},
        stackTrace: stackTrace);
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Reject a connection request (called by factory)
  Future<bool> rejectConnection(String connectionId, {String? reason}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('factory_connections')
          .update({
            'status': 'rejected',
            'rejected_at': DateTime.now().toIso8601String(),
            'notes': reason != null ? '$reason\n${_connections.firstWhere((c) => c.id == connectionId, orElse: () => throw Exception()).notes ?? ''}' : null,
          })
          .eq('id', connectionId)
          .select()
          .single();

      // Update local connection
      final index = _connections.indexWhere((c) => c.id == connectionId);
      if (index != -1) {
        _connections[index] = _parseConnection(response.data);
      }

      notifyListeners();
      debugPrint('[SellerFactoryConnection] Rejected connection: $connectionId');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'rejectConnection',
        context: {'connection_id': connectionId},
        stackTrace: stackTrace);
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Block a connection
  Future<bool> blockConnection(String connectionId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase
          .from('factory_connections')
          .update({
            'status': 'blocked',
          })
          .eq('id', connectionId);

      // Update local connection
      final index = _connections.indexWhere((c) => c.id == connectionId);
      if (index != -1) {
        _connections[index] = _connections[index].copyWith(
          status: ConnectionStatus.blocked,
        );
      }

      notifyListeners();
      debugPrint('[SellerFactoryConnection] Blocked connection: $connectionId');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'blockConnection',
        context: {'connection_id': connectionId},
        stackTrace: stackTrace);
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Create a product exchange
  Future<ProductExchange?> createExchange({
    required String connectionId,
    required String productId,
    required String productName,
    required String toPartyId,
    required ExchangeType exchangeType,
    required int quantity,
    required double unitPrice,
    String? notes,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated');
    }

    try {
      _isLoading = true;
      notifyListeners();

      final totalPrice = quantity * unitPrice;
      final now = DateTime.now().toIso8601String();

      final response = await _supabase.from('product_exchanges').insert({
        'connection_id': connectionId,
        'product_id': productId,
        'product_name': productName,
        'from_party_id': _currentUserId,
        'to_party_id': toPartyId,
        'exchange_type': exchangeType.toString().split('.').last,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'notes': notes,
        'status': 'pending',
        'created_at': now,
      }).select().single();

      final exchange = ProductExchange.fromJson(response.data);
      _exchanges.add(exchange);
      
      // Add product to connection's exchanged products
      final connIndex = _connections.indexWhere((c) => c.id == connectionId);
      if (connIndex != -1) {
        final connection = _connections[connIndex];
        if (!connection.exchangedProductIds.contains(productId)) {
          final updatedProducts = [...connection.exchangedProductIds, productId];
          // Note: We'd need to update the connection in DB too for this
        }
      }
      
      notifyListeners();
      debugPrint('[SellerFactoryConnection] Created exchange: ${exchange.id}');
      return exchange;
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'createExchange',
        context: {'connection_id': connectionId, 'product_id': productId},
        stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Update exchange status
  Future<bool> updateExchangeStatus(String exchangeId, ExchangeStatus status) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
      };

      if (status == ExchangeStatus.completed) {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('product_exchanges')
          .update(updates)
          .eq('id', exchangeId);

      // Update local exchange
      final index = _exchanges.indexWhere((e) => e.id == exchangeId);
      if (index != -1) {
        _exchanges[index] = _exchanges[index].copyWith(
          status: status,
          completedAt: status == ExchangeStatus.completed ? DateTime.now() : null,
        );
      }

      notifyListeners();
      debugPrint('[SellerFactoryConnection] Updated exchange $exchangeId status to $status');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'updateExchangeStatus',
        context: {'exchange_id': exchangeId},
        stackTrace: stackTrace);
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Get exchanges for a specific connection
  List<ProductExchange> getExchangesForConnection(String connectionId) {
    return _exchanges.where((e) => e.connectionId == connectionId).toList();
  }

  /// Get total volume for a connection
  double getTotalVolumeForConnection(String connectionId) {
    return _exchanges
        .where((e) => e.connectionId == connectionId && e.status == ExchangeStatus.completed)
        .fold(0.0, (sum, e) => sum + e.totalPrice);
  }

  /// Get total deals count for a connection
  int getDealsCountForConnection(String connectionId) {
    return _exchanges
        .where((e) => e.connectionId == connectionId && e.status == ExchangeStatus.completed)
        .length;
  }

  /// Search factories by name
  Future<List<Map<String, dynamic>>> searchFactories(String query) async {
    try {
      final response = await _supabase
          .from('sellers')
          .select('user_id, full_name, factory_name, location, specialization')
          .eq('is_factory', true)
          .ilike('factory_name', '%$query%');

      return List<Map<String, dynamic>>.from(response.data ?? []);
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'searchFactories',
        context: {'query': query},
        stackTrace: stackTrace);
      return [];
    }
  }

  /// Get nearby factories (requires latitude/longitude)
  Future<List<Map<String, dynamic>>> getNearbyFactories({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      // Simple bounding box query (more accurate would use PostGIS)
      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * (latitude.abs() * 3.14159 / 180).cos());

      final response = await _supabase
          .from('sellers')
          .select('user_id, full_name, factory_name, location, latitude, longitude, specialization')
          .eq('is_factory', true)
          .gte('latitude', latitude - latDelta)
          .lte('latitude', latitude + latDelta)
          .gte('longitude', longitude - lngDelta)
          .lte('longitude', longitude + lngDelta);

      return List<Map<String, dynamic>>.from(response.data ?? []);
    } catch (e, stackTrace) {
      _errorHandler.handleError(e, 'getNearbyFactories',
        context: {'latitude': latitude, 'longitude': longitude},
        stackTrace: stackTrace);
      return [];
    }
  }
}
