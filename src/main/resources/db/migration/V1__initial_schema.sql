CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==========================================
-- ISOLATED DATABASE SCHEMAS
-- ==========================================
CREATE SCHEMA IF NOT EXISTS auth_schema;
CREATE SCHEMA IF NOT EXISTS billing_schema;
CREATE SCHEMA IF NOT EXISTS ops_schema;
CREATE SCHEMA IF NOT EXISTS supplier_schema;
CREATE SCHEMA IF NOT EXISTS strategic_schema;
CREATE SCHEMA IF NOT EXISTS general_schema;

-- ==========================================
-- MODULE: SAAS CORE & TENANTS (auth_schema)
-- ==========================================
CREATE TABLE auth_schema.global_user (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- SAAS_ADMIN, CLIENT
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    profile_image TEXT
);

CREATE TABLE auth_schema.farm_tenant (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    cnpj VARCHAR(20) UNIQUE NOT NULL,
    owner_id UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_farm_owner FOREIGN KEY (owner_id) REFERENCES auth_schema.global_user (id) ON DELETE CASCADE
);

CREATE TABLE auth_schema.user_farm_link (
    user_id UUID NOT NULL,
    farm_id UUID NOT NULL,
    access_role VARCHAR(50) NOT NULL, -- FARM_OWNER, MANAGER, FIELD_WORKER
    PRIMARY KEY (user_id, farm_id),
    CONSTRAINT fk_link_user FOREIGN KEY (user_id) REFERENCES auth_schema.global_user (id) ON DELETE CASCADE,
    CONSTRAINT fk_link_farm FOREIGN KEY (farm_id) REFERENCES auth_schema.farm_tenant (id) ON DELETE CASCADE
);

CREATE TABLE auth_schema.employee_module_permission (
    employee_id UUID NOT NULL,
    farm_id     UUID NOT NULL,
    module_name VARCHAR(100) NOT NULL,
    is_enabled  BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (employee_id, farm_id, module_name),
    CONSTRAINT fk_emp_perm_user FOREIGN KEY (employee_id) REFERENCES auth_schema.global_user (id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_perm_farm FOREIGN KEY (farm_id)     REFERENCES auth_schema.farm_tenant  (id) ON DELETE CASCADE
);

-- ==========================================
-- MODULE: BILLING & SUBSCRIPTIONS (billing_schema)
-- ==========================================
CREATE TABLE billing_schema.saas_plan (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    max_tanks INTEGER NOT NULL DEFAULT 10,
    max_users INTEGER NOT NULL DEFAULT 5,
    price_monthly NUMERIC(10, 2) NOT NULL
);

CREATE TABLE billing_schema.subscription (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL UNIQUE,
    plan_id UUID NOT NULL,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL, -- ACTIVE, EXPIRED, CANCELLED
    CONSTRAINT fk_subscription_plan FOREIGN KEY (plan_id) REFERENCES billing_schema.saas_plan (id)
);

CREATE TABLE billing_schema.invoice (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    due_date DATE NOT NULL,
    paid_date DATE,
    status VARCHAR(20) NOT NULL, -- PENDING, PAID, OVERDUE
    CONSTRAINT fk_invoice_subscription FOREIGN KEY (subscription_id) REFERENCES billing_schema.subscription (id) ON DELETE CASCADE
);

-- ==========================================
-- MODULE: OPERATIONAL & METRICS (ops_schema)
-- ==========================================
CREATE TABLE ops_schema.tank (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    fish_species VARCHAR(100),
    fish_capacity INTEGER,
    average_weight_g INTEGER DEFAULT 0,
    mortality_count INTEGER DEFAULT 0,
    next_harvest_date DATE,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    custom_image TEXT
);

CREATE TABLE ops_schema.inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    item_name VARCHAR(150) NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL,
    unit VARCHAR(50),
    type VARCHAR(100)
);

CREATE TABLE ops_schema.feeding_record (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    tank_id UUID NOT NULL,
    user_id UUID NOT NULL,
    feed_id UUID NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL,
    feeding_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_feeding_tank FOREIGN KEY (tank_id) REFERENCES ops_schema.tank (id) ON DELETE CASCADE
);

CREATE TABLE ops_schema.water_quality (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    tank_id UUID NOT NULL,
    ph NUMERIC(4, 2),
    temperature NUMERIC(5, 2),
    dissolved_oxygen NUMERIC(5, 2),
    measurement_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_water_quality_tank FOREIGN KEY (tank_id) REFERENCES ops_schema.tank (id) ON DELETE CASCADE
);

CREATE TABLE ops_schema.harvest (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    tank_id UUID NOT NULL,
    date DATE NOT NULL,
    quantity_kg NUMERIC(10, 2) NOT NULL,
    destination VARCHAR(255),
    CONSTRAINT fk_harvest_tank FOREIGN KEY (tank_id) REFERENCES ops_schema.tank (id) ON DELETE CASCADE
);

CREATE TABLE ops_schema.maintenance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    tank_id UUID NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(50) NOT NULL,
    scheduled_date DATE,
    CONSTRAINT fk_maintenance_tank FOREIGN KEY (tank_id) REFERENCES ops_schema.tank (id) ON DELETE CASCADE
);

-- ==========================================
-- MODULE: MARKETPLACE (supplier_schema)
-- ==========================================
CREATE TABLE supplier_schema.national_supplier (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    cnpj VARCHAR(20) UNIQUE,
    supply_type VARCHAR(100) NOT NULL,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE
);

-- ==========================================
-- MODULE: STRATEGIC & FINANCE (strategic_schema)
-- ==========================================
CREATE TABLE strategic_schema.financial_transaction (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL, -- Income, Expense
    amount NUMERIC(10, 2) NOT NULL,
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- MODULE: GENERAL & WORKFLOWS (general_schema)
-- ==========================================
CREATE TABLE general_schema.notification (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_user_id UUID NOT NULL,
    type VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE general_schema.approval_request (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL,
    requester_id UUID NOT NULL,
    requested_action TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending', -- Pending, Approved, Rejected
    request_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
