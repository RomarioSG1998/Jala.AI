-- Create schema for marketplace if not exists
CREATE SCHEMA IF NOT EXISTS marketplace_schema;

-- Table for announcements (Marketplace)
CREATE TABLE marketplace_schema.announcement (
    id UUID PRIMARY KEY,
    farm_id UUID NOT NULL,
    category VARCHAR(30) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price NUMERIC(12, 2) NOT NULL,
    seller_name VARCHAR(150),
    seller_phone VARCHAR(20),
    seller_location VARCHAR(100),
    image_url TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Table for calculator history (ops_schema)
CREATE TABLE ops_schema.calculator_history (
    id UUID PRIMARY KEY,
    farm_id UUID NOT NULL,
    tank_id UUID,
    species VARCHAR(50),
    quantity INTEGER,
    weight_g NUMERIC(10, 2),
    biomass_kg NUMERIC(10, 2),
    daily_feed_kg NUMERIC(10, 2),
    feed_per_treatment_kg NUMERIC(10, 2),
    treatments_per_day INTEGER,
    protein_level VARCHAR(10),
    granulometry VARCHAR(30),
    days_to_harvest INTEGER,
    temperature_c NUMERIC(5, 1),
    temp_alert BOOLEAN,
    calculated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
