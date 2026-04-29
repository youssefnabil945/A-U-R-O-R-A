// ============================================================================
// Supabase Rate Limiter
// ============================================================================
// 
// Rate limiter for API calls to prevent abuse and throttling.
// ============================================================================

/// Rate limit entry for tracking call timing
class _RateLimitEntry {
  _RateLimitEntry({required this.limit});

  final Duration limit;

  DateTime? _lastCall;

  Future<void> wait() async {
    final now = DateTime.now();
    if (_lastCall != null) {
      final elapsed = now.difference(_lastCall!);
      if (elapsed < limit) {
        final delay = limit - elapsed;
        await Future.delayed(delay);
      }
    }
    _lastCall = DateTime.now();
  }
}

/// Rate limiter for API calls
class RateLimiter {
  RateLimiter({this.defaultLimit = const Duration(seconds: 1)});

  final Duration defaultLimit;

  final Map<String, _RateLimitEntry> _limits = {};

  /// Execute an operation with rate limiting
  Future<T> execute<T>(
    String key,
    Future<T> Function() operation, {
    Duration? limit,
  }) async {
    final entry = _limits[key] ??= _RateLimitEntry(
      limit: limit ?? defaultLimit,
    );

    await entry.wait();
    return await operation();
  }

  /// Reset rate limit for a specific key
  void reset(String key) {
    _limits.remove(key);
  }

  /// Reset all rate limits
  void resetAll() {
    _limits.clear();
  }
}
