-- ============================================================================
-- SELLER-FACTORY CONNECTION SYSTEM
-- ============================================================================
-- This migration creates tables for managing B2B connections between sellers 
-- and factories, enabling product exchange workflows.
-- Version: 1.0.0
-- Date: 2026-04-29
-- ============================================================================

-- Step 1: Create product_exchanges table if it doesn't exist
-- This table tracks individual product exchanges between connected parties
CREATE TABLE IF NOT EXISTS product_exchanges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  connection_id UUID REFERENCES factory_connections(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  from_party_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  to_party_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  exchange_type TEXT NOT NULL CHECK (exchange_type IN ('wholesale', 'consignment', 'dropshipping', 'custom_order')),
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Add exchanged_product_ids column to factory_connections if not exists
ALTER TABLE factory_connections
ADD COLUMN IF NOT EXISTS exchanged_product_ids TEXT[] DEFAULT '{}';

-- Step 3: Add total_deals and total_volume to factory_connections if not exist
ALTER TABLE factory_connections
ADD COLUMN IF NOT EXISTS total_deals INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_volume NUMERIC(12,2) DEFAULT 0.00;

-- Step 4: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_product_exchanges_connection_id 
  ON product_exchanges(connection_id);

CREATE INDEX IF NOT EXISTS idx_product_exchanges_from_party 
  ON product_exchanges(from_party_id);

CREATE INDEX IF NOT EXISTS idx_product_exchanges_to_party 
  ON product_exchanges(to_party_id);

CREATE INDEX IF NOT EXISTS idx_product_exchanges_status 
  ON product_exchanges(status);

CREATE INDEX IF NOT EXISTS idx_product_exchanges_created_at 
  ON product_exchanges(created_at DESC);

-- Step 5: Enable RLS on product_exchanges
ALTER TABLE product_exchanges ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own exchanges" ON product_exchanges;
DROP POLICY IF EXISTS "Users can create exchanges" ON product_exchanges;
DROP POLICY IF EXISTS "Users can update own exchanges" ON product_exchanges;

-- Create policies for product_exchanges
CREATE POLICY "Users can view own exchanges"
  ON product_exchanges FOR SELECT
  TO authenticated
  USING (from_party_id = auth.uid() OR to_party_id = auth.uid());

CREATE POLICY "Users can create exchanges"
  ON product_exchanges FOR INSERT
  TO authenticated
  WITH CHECK (from_party_id = auth.uid());

CREATE POLICY "Users can update own exchanges"
  ON product_exchanges FOR UPDATE
  TO authenticated
  USING (from_party_id = auth.uid() OR to_party_id = auth.uid())
  WITH CHECK (from_party_id = auth.uid() OR to_party_id = auth.uid());

-- Step 6: Create trigger to update timestamps
CREATE OR REPLACE FUNCTION update_product_exchanges_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_product_exchanges_updated_at ON product_exchanges;

CREATE TRIGGER update_product_exchanges_updated_at
  BEFORE UPDATE ON product_exchanges
  FOR EACH ROW
  EXECUTE FUNCTION update_product_exchanges_timestamp();

-- Step 7: Create function to update connection stats after exchange
CREATE OR REPLACE FUNCTION update_connection_stats_after_exchange()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update when exchange is completed
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE factory_connections
    SET 
      total_deals = COALESCE(total_deals, 0) + 1,
      total_volume = COALESCE(total_volume, 0) + NEW.total_price,
      exchanged_product_ids = CASE 
        WHEN NEW.product_id = ANY(exchanged_product_ids) THEN exchanged_product_ids
        ELSE array_append(exchanged_product_ids, NEW.product_id)
      END,
      updated_at = NOW()
    WHERE id = NEW.connection_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trg_update_connection_stats ON product_exchanges;

-- Create trigger to update connection stats
CREATE TRIGGER trg_update_connection_stats
  AFTER INSERT OR UPDATE ON product_exchanges
  FOR EACH ROW
  EXECUTE FUNCTION update_connection_stats_after_exchange();

-- Step 8: Update factory_connections RLS policies to support updates
DROP POLICY IF EXISTS "Factories can update own connections" ON factory_connections;

CREATE POLICY "Factories can update own connections"
  ON factory_connections FOR UPDATE
  TO authenticated
  USING (factory_id = auth.uid())
  WITH CHECK (factory_id = auth.uid());

-- Allow both parties to update connection status
DROP POLICY IF EXISTS "Either party can update connection" ON factory_connections;

CREATE POLICY "Either party can update connection"
  ON factory_connections FOR UPDATE
  TO authenticated
  USING (seller_id = auth.uid() OR factory_id = auth.uid())
  WITH CHECK (seller_id = auth.uid() OR factory_id = auth.uid());

-- Step 9: Grant permissions
GRANT ALL ON TABLE product_exchanges TO authenticated;
GRANT ALL ON TABLE factory_connections TO authenticated;
GRANT ALL ON FUNCTION update_connection_stats_after_exchange() TO authenticated;

-- Step 10: Verification queries
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'product_exchanges'
ORDER BY ordinal_position;

-- Show all factory connection related tables
SELECT 
  table_name,
  COUNT(*) as row_count
FROM (
  SELECT 'factory_connections' as table_name FROM factory_connections
  UNION ALL
  SELECT 'product_exchanges' as table_name FROM product_exchanges
) subq
GROUP BY table_name;

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

-- Example 1: Seller requests connection with factory
-- INSERT INTO factory_connections (factory_id, seller_id, status, notes)
-- VALUES ('factory-uuid', 'seller-uuid', 'pending', 'Interested in your products');

-- Example 2: Factory accepts connection
-- UPDATE factory_connections 
-- SET status = 'accepted', accepted_at = NOW()
-- WHERE id = 'connection-uuid' AND factory_id = auth.uid();

-- Example 3: Create product exchange (wholesale order)
-- INSERT INTO product_exchanges (
--   connection_id, product_id, product_name, from_party_id, to_party_id,
--   exchange_type, quantity, unit_price, total_price, status
-- ) VALUES (
--   'connection-uuid', 'prod-123', 'Widget A', 'seller-uuid', 'factory-uuid',
--   'wholesale', 100, 10.50, 1050.00, 'pending'
-- );

-- Example 4: Update exchange status to completed
-- UPDATE product_exchanges 
-- SET status = 'completed', completed_at = NOW()
-- WHERE id = 'exchange-uuid';

-- Example 5: Get all exchanges for a connection with totals
-- SELECT 
--   pe.*,
--   fc.status as connection_status
-- FROM product_exchanges pe
-- JOIN factory_connections fc ON pe.connection_id = fc.id
-- WHERE pe.connection_id = 'connection-uuid'
-- ORDER BY pe.created_at DESC;

-- Example 6: Get connection statistics
-- SELECT 
--   fc.id,
--   fc.factory_id,
--   fc.seller_id,
--   fc.status,
--   COUNT(pe.id) as total_exchanges,
--   SUM(CASE WHEN pe.status = 'completed' THEN pe.total_price ELSE 0 END) as total_volume,
--   COUNT(CASE WHEN pe.status = 'completed' THEN 1 END) as completed_deals
-- FROM factory_connections fc
-- LEFT JOIN product_exchanges pe ON fc.id = pe.connection_id
-- WHERE fc.factory_id = auth.uid() OR fc.seller_id = auth.uid()
-- GROUP BY fc.id, fc.factory_id, fc.seller_id, fc.status;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
