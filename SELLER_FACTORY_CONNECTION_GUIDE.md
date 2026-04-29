# Seller-Factory Connection System

## Overview

This feature enables B2B connections between sellers and factories in the Aurora platform, facilitating product exchange workflows including wholesale, consignment, dropshipping, and custom orders.

## Architecture

### Components

1. **Models** (`lib/models/seller_factory_connection.dart`)
   - `SellerFactoryConnection` - Represents a connection between seller and factory
   - `ProductExchange` - Tracks individual product exchanges
   - `ConnectionStatus` - Enum for connection states
   - `ExchangeType` - Enum for exchange types
   - `ExchangeStatus` - Enum for exchange workflow states

2. **Service** (`lib/services/seller_factory_connection_service.dart`)
   - `SellerFactoryConnectionService` - Manages all connection and exchange operations

3. **Database** (`supabase/migrations/013_seller_factory_connection_system.sql`)
   - `product_exchanges` table - Tracks product exchanges
   - Enhanced `factory_connections` table - Added exchange tracking fields

## Features

### Connection Management

- **Request Connection**: Sellers can send connection requests to factories
- **Accept/Reject**: Factories can accept or reject connection requests
- **Block**: Either party can block a connection
- **Search Factories**: Find factories by name or location
- **Nearby Factories**: Discover factories within a geographic radius

### Product Exchange

Four exchange types supported:

1. **Wholesale** - Factory sells products in bulk to seller
2. **Consignment** - Factory places products on consignment with seller
3. **Dropshipping** - Factory ships directly to customer on behalf of seller
4. **Custom Order** - Custom manufacturing order from seller

Exchange workflow states:
- `pending` → `confirmed` → `in_progress` → `completed`
- Any state → `cancelled`

### Automatic Statistics

The system automatically tracks:
- Total deals per connection
- Total volume (revenue) per connection
- List of exchanged product IDs
- Connection duration

## Usage

### Initialize Service

```dart
import 'package:aurora/services/seller_factory_connection_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
final connectionService = SellerFactoryConnectionService(supabase: supabase);
```

### Request Connection with Factory

```dart
try {
  final connection = await connectionService.requestConnection(
    factoryId: 'factory-user-uuid',
    notes: 'Interested in your textile products for my retail store',
  );
  
  if (connection != null) {
    print('Connection requested: ${connection.id}');
  }
} catch (e) {
  print('Failed to request connection: $e');
}
```

### Accept Connection (Factory)

```dart
final success = await connectionService.acceptConnection(connectionId);
if (success) {
  print('Connection accepted!');
}
```

### Create Product Exchange

```dart
final exchange = await connectionService.createExchange(
  connectionId: 'connection-uuid',
  productId: 'product-123',
  productName: 'Premium Cotton Shirt',
  toPartyId: 'factory-user-uuid',
  exchangeType: ExchangeType.wholesale,
  quantity: 100,
  unitPrice: 15.50,
  notes: 'Rush order needed by end of month',
);
```

### Update Exchange Status

```dart
// Confirm the exchange
await connectionService.updateExchangeStatus(
  exchangeId,
  ExchangeStatus.confirmed,
);

// Mark as completed
await connectionService.updateExchangeStatus(
  exchangeId,
  ExchangeStatus.completed,
);
```

### Get Connection Statistics

```dart
// Get all connections
final connections = connectionService.connections;

// Get pending requests
final pending = connectionService.pendingConnections;

// Get accepted connections
final accepted = connectionService.acceptedConnections;

// Get exchanges for specific connection
final exchanges = connectionService.getExchangesForConnection(connectionId);

// Get total volume for connection
final volume = connectionService.getTotalVolumeForConnection(connectionId);

// Get deals count
final dealCount = connectionService.getDealsCountForConnection(connectionId);
```

### Search Factories

```dart
// Search by name
final factories = await connectionService.searchFactories('textile');

// Get nearby factories
final nearby = await connectionService.getNearbyFactories(
  latitude: 30.0444,
  longitude: 31.2357,
  radiusKm: 50.0,
);
```

## Database Schema

### factory_connections Table

```sql
CREATE TABLE factory_connections (
  id UUID PRIMARY KEY,
  factory_id UUID REFERENCES sellers(user_id),
  seller_id UUID REFERENCES sellers(user_id),
  status TEXT CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
  requested_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  notes TEXT,
  exchanged_product_ids TEXT[],
  total_deals INTEGER DEFAULT 0,
  total_volume NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  UNIQUE(factory_id, seller_id)
);
```

### product_exchanges Table

```sql
CREATE TABLE product_exchanges (
  id UUID PRIMARY KEY,
  connection_id UUID REFERENCES factory_connections(id),
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  from_party_id UUID REFERENCES auth.users(id),
  to_party_id UUID REFERENCES auth.users(id),
  exchange_type TEXT CHECK (exchange_type IN ('wholesale', 'consignment', 'dropshipping', 'custom_order')),
  quantity INTEGER NOT NULL,
  unit_price NUMERIC(12,2) NOT NULL,
  total_price NUMERIC(12,2) NOT NULL,
  notes TEXT,
  status TEXT CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);
```

## Security

### Row Level Security (RLS)

Both tables have RLS policies ensuring:
- Users can only view their own connections and exchanges
- Only the requesting party can create connections
- Both parties can update connection status
- Only involved parties can view/update exchanges

### Permissions

```sql
GRANT ALL ON TABLE product_exchanges TO authenticated;
GRANT ALL ON TABLE factory_connections TO authenticated;
```

## Integration with Existing Systems

### Chat System

Connection requests can be initiated from chat conversations:
- Use `DealProposal` model for initial terms discussion
- Convert accepted proposals to `SellerFactoryConnection`
- Track ongoing communication alongside exchanges

### Product System

- Exchanged products reference existing product IDs
- Product metadata can include factory/seller relationship info
- QR codes can link back to exchange history

### Analytics

- Connection metrics available in analytics dashboard
- Exchange volume contributes to business intelligence
- Factory ratings can be calculated from exchange history

## Future Enhancements

1. **Rating System**: Allow sellers to rate factories after completed exchanges
2. **Automated Notifications**: Push notifications for connection requests and exchange updates
3. **Contract Templates**: Standardized terms for different exchange types
4. **Escrow Payments**: Integrated payment holding for secure transactions
5. **Shipping Integration**: Track shipments for physical product exchanges
6. **Analytics Dashboard**: Visual insights into connection performance

## Testing

### Unit Tests

```dart
test('Should create connection request', () async {
  final connection = await service.requestConnection(
    factoryId: 'test-factory-id',
    notes: 'Test connection',
  );
  
  expect(connection, isNotNull);
  expect(connection.status, ConnectionStatus.pending);
});

test('Should accept connection', () async {
  final success = await service.acceptConnection('connection-id');
  expect(success, isTrue);
});
```

### Integration Tests

Test full workflow:
1. Seller discovers factory
2. Seller requests connection
3. Factory accepts
4. Create product exchange
5. Update exchange through workflow
6. Verify statistics updated

## Troubleshooting

### Common Issues

**Issue**: Connection request fails with permission error
- **Solution**: Ensure user is authenticated and has seller account type

**Issue**: Exchange not updating connection stats
- **Solution**: Verify trigger `trg_update_connection_stats` is installed

**Issue**: Can't see factory in search results
- **Solution**: Check that factory has `is_factory = true` in sellers table

## Migration

To apply the database changes:

```bash
cd supabase
supabase db push
```

Or manually run the migration SQL file in your Supabase SQL editor.

## Support

For issues or questions, refer to:
- `/workspace/FACTORY_IMPLEMENTATION.md` - Factory system overview
- `/workspace/CHAT_SYSTEM_IMPLEMENTATION.md` - Chat integration
- `/workspace/supabase/migrations/012_add_factory_support_to_sellers.sql` - Previous factory migration
