-- ==========================================
-- ADD DELIVERY DETAILS & BUYER CONTACT TO MARKETPLACE ORDER
-- ==========================================
ALTER TABLE marketplace_schema.marketplace_order
ADD COLUMN IF NOT EXISTS buyer_name VARCHAR(150),
ADD COLUMN IF NOT EXISTS buyer_phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS delivery_address TEXT,
ADD COLUMN IF NOT EXISTS delivery_city VARCHAR(100),
ADD COLUMN IF NOT EXISTS delivery_state VARCHAR(2),
ADD COLUMN IF NOT EXISTS delivery_notes TEXT;
