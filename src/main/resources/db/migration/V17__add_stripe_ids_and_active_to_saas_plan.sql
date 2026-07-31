-- ======================================================
-- ADD STRIPE IDs, DESCRIPTION & ACTIVE STATUS TO SAAS PLAN
-- ======================================================

ALTER TABLE billing_schema.saas_plan
ADD COLUMN IF NOT EXISTS stripe_product_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS stripe_price_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT TRUE;
