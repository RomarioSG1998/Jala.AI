-- ======================================================
-- SUPPLIER PROFILES & ENHANCED PRODUCT ANNOUNCEMENTS
-- ======================================================

-- 1. Create supplier_profile table
CREATE TABLE IF NOT EXISTS marketplace_schema.supplier_profile (
    id UUID PRIMARY KEY,
    farm_id UUID NOT NULL UNIQUE,
    company_name VARCHAR(200) NOT NULL,
    document_number VARCHAR(20),
    state_registration VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(150),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(2),
    pix_key VARCHAR(100),
    pix_key_type VARCHAR(20),
    verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Add enhanced product details to announcement table
ALTER TABLE marketplace_schema.announcement
ADD COLUMN IF NOT EXISTS stock_quantity INT DEFAULT 100,
ADD COLUMN IF NOT EXISTS unit_measure VARCHAR(50) DEFAULT 'Unidade',
ADD COLUMN IF NOT EXISTS min_order_quantity INT DEFAULT 1,
ADD COLUMN IF NOT EXISTS delivery_terms VARCHAR(255),
ADD COLUMN IF NOT EXISTS specifications TEXT;
