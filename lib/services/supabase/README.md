# Supabase Module

This directory contains refactored, modular components for Supabase operations.

## Structure

```
supabase/
├── exports.dart              # Barrel export file - import this for all modules
├── supabase_constants.dart   # Constants for tables, functions, cache keys
├── supabase_types.dart       # Type definitions and error handling
├── cache_manager.dart        # Memory + disk caching utilities
├── rate_limiter.dart         # API rate limiting
├── enums.dart                # Enumerations
└── README.md                 # This file
```

## Usage

### Import All Modules
```dart
import 'package:aurora/services/supabase/exports.dart';
```

### Import Specific Module
```dart
import 'package:aurora/services/supabase/supabase_constants.dart';
import 'package:aurora/services/supabase/cache_manager.dart';
```

## Modules

### supabase_constants.dart
Centralized constants for:
- Database table names
- Edge function names
- Cache keys
- User metadata keys

**Example:**
```dart
final tableName = SupabaseConstants.tableProducts;
const cacheKey = SupabaseConstants.cacheProducts;
```

### supabase_types.dart
Shared type definitions:
- `AuthResult` - Standardized auth operation result
- `DataResult<T>` - Generic data operation result
- `PaginationResult<T>` - Paginated query result
- `AppError` - Error model
- `GlobalErrorHandler` - Centralized error handling

**Example:**
```dart
AuthResult result = (success: true, message: 'OK', data: userData);
DataResult<List<Product>> products = DataResult(success: true, ...);
```

### cache_manager.dart
Two-tier caching (memory + disk):
- Automatic expiry handling
- Thread-safe operations
- Configurable cache duration

**Example:**
```dart
final cache = CacheManager();
await cache.init();
await cache.set('key', value, Duration(minutes: 5));
final cached = await cache.get<String>('key');
```

### rate_limiter.dart
API rate limiting to prevent throttling:
- Per-key rate limiting
- Configurable limits
- Automatic queuing

**Example:**
```dart
final limiter = RateLimiter(defaultLimit: Duration(seconds: 1));
await limiter.execute('login_user123', () => loginOperation());
```

### enums.dart
Common enumerations:
- `AccountType` - User account types
- `OrderStatus` - Order lifecycle states
- `NotificationType` - Notification categories

## Migration Guide

### Before (Old Pattern)
```dart
import 'package:aurora/services/supabase.dart';

// Access constants through SupabaseProvider
final table = SupabaseConstants.tableProducts;
```

### After (New Pattern)
```dart
import 'package:aurora/services/supabase/exports.dart';

// Direct access to constants
final table = SupabaseConstants.tableProducts;
```

## Best Practices

1. **Use the barrel export** (`exports.dart`) for convenience imports
2. **Prefer specific imports** in production code to reduce bundle size
3. **Use constants** instead of hardcoded strings
4. **Implement caching** for frequently accessed data
5. **Apply rate limiting** for user-triggered API calls

## Testing

Each module is designed to be independently testable:

```dart
test('CacheManager stores and retrieves values', () async {
  final cache = CacheManager();
  await cache.init();
  await cache.set('test', 'value');
  expect(await cache.get<String>('test'), equals('value'));
});
```

## Future Enhancements

Planned additions:
- [ ] Query builder utilities
- [ ] Batch operation helpers
- [ ] Offline sync manager
- [ ] Real-time subscription manager
