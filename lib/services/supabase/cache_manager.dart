// ============================================================================
// Supabase Cache Manager
// ============================================================================
// 
// Manages local caching for improved performance with both memory and disk cache.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache entry with optional expiry
class _CacheEntry {
  _CacheEntry({required this.data, this.expiry});

  final dynamic data;
  final int? expiry;

  bool get isExpired =>
      expiry != null && DateTime.now().millisecondsSinceEpoch > expiry!;
}

/// Manages local caching for improved performance
class CacheManager {
  factory CacheManager() => _instance;

  CacheManager._internal();

  static final CacheManager _instance = CacheManager._internal();

  final Map<String, _CacheEntry> _memoryCache = {};
  SharedPreferences? _prefs;

  /// Initialize the cache manager
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get a value from cache (memory first, then disk)
  Future<T?> get<T>(String key) async {
    // Check memory cache first
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return memoryEntry.data as T?;
    }

    // Fall back to disk cache
    if (_prefs == null) await init();
    final data = _prefs?.getString(key);
    if (data == null) return null;

    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final expiry = decoded['expiry'] as int?;
      if (expiry != null && DateTime.now().millisecondsSinceEpoch > expiry) {
        await remove(key);
        return null;
      }
      return decoded['data'] as T;
    } catch (e) {
      return null;
    }
  }

  /// Set a value in cache (both memory and disk)
  Future<void> set<T>(String key, T value, [Duration? duration]) async {
    if (_prefs == null) await init();

    final expiry = duration != null
        ? DateTime.now().add(duration).millisecondsSinceEpoch
        : null;

    // Store in memory
    _memoryCache[key] = _CacheEntry(data: value, expiry: expiry);

    // Store on disk
    final encoded = jsonEncode({'data': value, 'expiry': expiry});
    await _prefs?.setString(key, encoded);
  }

  /// Remove a value from cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    if (_prefs == null) await init();
    await _prefs?.remove(key);
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    if (_prefs == null) await init();
    await _prefs?.clear();
  }

  /// Clear expired cache entries
  Future<void> clearExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final toRemove = <String>[];

    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      await remove(key);
    }
  }
}
