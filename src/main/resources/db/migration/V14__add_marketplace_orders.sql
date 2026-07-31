-- ==========================================
-- MODULE: MARKETPLACE ORDERS & ESCROW PAYMENTS (marketplace_schema)
-- ==========================================
CREATE TABLE IF NOT EXISTS marketplace_schema.marketplace_order (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    announcement_id UUID NOT NULL,
    buyer_farm_id UUID NOT NULL,
    seller_farm_id UUID NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(12, 2) NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING_PAYMENT', -- PENDING_PAYMENT, PAID_HELD, DELIVERED_RELEASED, CANCELLED
    payment_method VARCHAR(50) NOT NULL DEFAULT 'PIX', -- PIX, CARD
    stripe_payment_intent_id VARCHAR(255),
    stripe_client_secret VARCHAR(255),
    pix_qr_code TEXT,
    pix_copy_paste TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP
);
