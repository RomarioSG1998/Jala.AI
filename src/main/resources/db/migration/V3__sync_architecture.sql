-- V2__sync_architecture.sql
-- Synchronizing the V1 legacy schema to the modern Domain-Driven Design JPA Entities.

-- 1. FarmTenant
ALTER TABLE farm_tenant RENAME COLUMN farm_name TO name;
ALTER TABLE farm_tenant RENAME COLUMN owner_user_id TO owner_id;
ALTER TABLE farm_tenant ADD COLUMN cnpj VARCHAR(20) UNIQUE;
ALTER TABLE farm_tenant ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE farm_tenant DROP COLUMN location;

-- 2. SaaSPlan
ALTER TABLE saas_plan RENAME COLUMN monthly_price TO price_monthly;
ALTER TABLE saas_plan ADD COLUMN max_tanks INTEGER NOT NULL DEFAULT 10;
ALTER TABLE saas_plan ADD COLUMN max_users INTEGER NOT NULL DEFAULT 5;

-- 3. Subscription
ALTER TABLE subscription DROP COLUMN due_date;
ALTER TABLE subscription ADD COLUMN start_date DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subscription ADD COLUMN end_date DATE NOT NULL DEFAULT CURRENT_DATE;

-- 4. Invoice (New)
CREATE TABLE invoice (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    due_date DATE NOT NULL,
    paid_date DATE,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_invoice_subscription FOREIGN KEY (subscription_id) REFERENCES subscription (id) ON DELETE CASCADE
);

-- 5. FeedingRecord
ALTER TABLE feeding RENAME TO feeding_record;
ALTER TABLE feeding_record RENAME COLUMN date_time TO feeding_time;
ALTER TABLE feeding_record RENAME COLUMN quantity_kg TO quantity;
ALTER TABLE feeding_record ADD COLUMN farm_id UUID NOT NULL DEFAULT uuid_generate_v4();
ALTER TABLE feeding_record ADD COLUMN feed_id UUID NOT NULL DEFAULT uuid_generate_v4();
ALTER TABLE feeding_record ADD COLUMN user_id UUID NOT NULL DEFAULT uuid_generate_v4();

-- 6. WaterQuality
ALTER TABLE water_measurement RENAME TO water_quality;
ALTER TABLE water_quality RENAME COLUMN date_time TO measurement_time;
ALTER TABLE water_quality ADD COLUMN farm_id UUID NOT NULL DEFAULT uuid_generate_v4();
ALTER TABLE water_quality ADD COLUMN dissolved_oxygen NUMERIC(5, 2);

-- 7. Maintenance
ALTER TABLE maintenance RENAME COLUMN equipment TO description;
ALTER TABLE maintenance ADD COLUMN tank_id UUID NOT NULL DEFAULT uuid_generate_v4();

-- 8. Harvest (New)
CREATE TABLE harvest (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    tank_id UUID NOT NULL,
    date DATE NOT NULL,
    quantity_kg NUMERIC(10, 2) NOT NULL,
    destination VARCHAR(255),
    CONSTRAINT fk_harvest_farm FOREIGN KEY (farm_id) REFERENCES farm_tenant (id) ON DELETE CASCADE,
    CONSTRAINT fk_harvest_tank FOREIGN KEY (tank_id) REFERENCES tank (id) ON DELETE CASCADE
);

-- 9. Inventory
ALTER TABLE inventory RENAME COLUMN item TO item_name;
ALTER TABLE inventory ADD COLUMN unit VARCHAR(50);
ALTER TABLE inventory ADD COLUMN type VARCHAR(100);
