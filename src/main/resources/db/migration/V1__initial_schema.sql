CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- MODULE: SAAS CORE (GLOBAL & MARKETPLACE)
-- ==========================================

CREATE TABLE global_user (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- SAAS_ADMIN, CLIENT
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE national_supplier (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    cnpj VARCHAR(20) UNIQUE,
    supply_type VARCHAR(100) NOT NULL,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE
);

-- ==========================================
-- MODULE: TENANTS (FARM ENVIRONMENT)
-- ==========================================

CREATE TABLE farm_tenant (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_user_id UUID NOT NULL,
    farm_name VARCHAR(255) NOT NULL,
    location TEXT,
    CONSTRAINT fk_farm_owner FOREIGN KEY (owner_user_id) REFERENCES global_user (id) ON DELETE CASCADE
);

CREATE TABLE user_farm_link (
    user_id UUID NOT NULL,
    farm_id UUID NOT NULL,
    access_role VARCHAR(50) NOT NULL, -- FARM_OWNER, MANAGER, FIELD_WORKER
    PRIMARY KEY (user_id, farm_id),
    CONSTRAINT fk_link_user FOREIGN KEY (user_id) REFERENCES global_user (id) ON DELETE CASCADE,
    CONSTRAINT fk_link_farm FOREIGN KEY (farm_id) REFERENCES farm_tenant (id) ON DELETE CASCADE
);

-- ==========================================
-- MODULE: BILLING & SUBSCRIPTIONS
-- ==========================================

CREATE TABLE saas_plan (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    monthly_price NUMERIC(10, 2) NOT NULL
);

CREATE TABLE subscription (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL UNIQUE,
    plan_id UUID NOT NULL,
    status VARCHAR(50) NOT NULL, -- Active, Canceled, Overdue
    due_date DATE,
    CONSTRAINT fk_subscription_farm FOREIGN KEY (farm_id) REFERENCES farm_tenant (id) ON DELETE CASCADE,
    CONSTRAINT fk_subscription_plan FOREIGN KEY (plan_id) REFERENCES saas_plan (id)
);

-- ==========================================
-- MODULE: OPERATIONAL (OWNER & FIELD WORKERS)
-- ==========================================

CREATE TABLE tank (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    fish_species VARCHAR(100),
    fish_capacity INTEGER,
    CONSTRAINT fk_tank_farm FOREIGN KEY (farm_id) REFERENCES farm_tenant (id) ON DELETE CASCADE
);

CREATE TABLE feeding (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tank_id UUID NOT NULL,
    date_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    quantity_kg NUMERIC(10, 2) NOT NULL,
    CONSTRAINT fk_feeding_tank FOREIGN KEY (tank_id) REFERENCES tank (id) ON DELETE CASCADE
);

CREATE TABLE water_measurement (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tank_id UUID NOT NULL,
    date_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ph NUMERIC(4, 2),
    temperature NUMERIC(5, 2),
    CONSTRAINT fk_measurement_tank FOREIGN KEY (tank_id) REFERENCES tank (id) ON DELETE CASCADE
);

CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    national_supplier_id UUID,
    item VARCHAR(255) NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL,
    CONSTRAINT fk_inventory_farm FOREIGN KEY (farm_id) REFERENCES farm_tenant (id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_supplier FOREIGN KEY (national_supplier_id) REFERENCES national_supplier (id) ON DELETE SET NULL
);

-- ==========================================
-- MODULE: OWNER EXCLUSIVE & WORKFLOWS
-- ==========================================

CREATE TABLE financial_transaction (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL, -- Income, Expense
    amount NUMERIC(10, 2) NOT NULL,
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_transaction_farm FOREIGN KEY (farm_id) REFERENCES farm_tenant (id) ON DELETE CASCADE
);

CREATE TABLE maintenance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    equipment VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    scheduled_date DATE,
    CONSTRAINT fk_maintenance_farm FOREIGN KEY (farm_id) REFERENCES farm_tenant (id) ON DELETE CASCADE
);

CREATE TABLE approval_request (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    requester_id UUID NOT NULL,
    requested_action TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending', -- Pending, Approved, Rejected
    request_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_approval_farm FOREIGN KEY (farm_id) REFERENCES farm_tenant (id) ON DELETE CASCADE,
    CONSTRAINT fk_approval_requester FOREIGN KEY (requester_id) REFERENCES global_user (id) ON DELETE CASCADE
);

CREATE TABLE notification (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_user_id UUID NOT NULL,
    type VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notification_user FOREIGN KEY (target_user_id) REFERENCES global_user (id) ON DELETE CASCADE
);
