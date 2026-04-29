// ============================================================================
// Supabase Type Definitions & Error Handling
// ============================================================================
// 
// Shared types, error classes, and utilities for Supabase operations.
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;

// ============================================================================
// Type Definitions
// ============================================================================

/// Standardized result for authentication operations
typedef AuthResult = ({
  bool success,
  String message,
  Map<String, dynamic>? data,
});

/// Standardized result for data operations
class DataResult<T> {
  DataResult({
    required this.success,
    required this.message,
    required this.data,
    this.error,
  });

  final T? data;
  final String? error;
  final String message;
  final bool success;

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data,
    'error': error,
  };
}

/// Pagination Result for paginated queries
class PaginationResult<T> {
  PaginationResult({
    required this.success,
    required this.message,
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int limit;
  final String message;
  final int page;
  final bool success;
  final int total;
  final int totalPages;

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'items': items,
    'page': page,
    'limit': limit,
    'total': total,
    'totalPages': totalPages,
  };
}

// ============================================================================
// Error Handling
// ============================================================================

/// Application Error Model
class AppError {
  AppError({
    required this.error,
    this.context,
    required this.timestamp,
  });

  final String? context;
  final Object error;
  final DateTime timestamp;

  String get message => error.toString();
  String get type => error.runtimeType.toString();

  Map<String, dynamic> toJson() => {
    'error': message,
    'type': type,
    'context': context,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Global error handler for consistent error management
class GlobalErrorHandler {
  factory GlobalErrorHandler() => _instance;

  GlobalErrorHandler._internal();

  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();

  final StreamController<AppError> _errorController =
      StreamController<AppError>.broadcast();

  Stream<AppError> get errorStream => _errorController.stream;

  void handleError(Object error, [String? context]) {
    final appError = AppError(
      error: error,
      context: context,
      timestamp: DateTime.now(),
    );
    _errorController.add(appError);

    if (kDebugMode) {
      debugPrint('❌ [Error] $context: ${error.toString()}');
      if (error is Exception) {
        debugPrint('StackTrace: ${StackTrace.current}');
      }
    }
  }

  void dispose() {
    _errorController.close();
  }
}
