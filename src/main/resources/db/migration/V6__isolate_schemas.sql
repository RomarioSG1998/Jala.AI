-- Create isolated database schemas representingBounded Contexts / Microservices
CREATE SCHEMA IF NOT EXISTS auth_schema;
CREATE SCHEMA IF NOT EXISTS billing_schema;
CREATE SCHEMA IF NOT EXISTS ops_schema;
CREATE SCHEMA IF NOT EXISTS supplier_schema;
CREATE SCHEMA IF NOT EXISTS strategic_schema;
CREATE SCHEMA IF NOT EXISTS general_schema;

-- Move Identity & Tenant tables to auth_schema
ALTER TABLE global_user SET SCHEMA auth_schema;
ALTER TABLE farm_tenant SET SCHEMA auth_schema;
ALTER TABLE user_farm_link SET SCHEMA auth_schema;
ALTER TABLE employee_module_permission SET SCHEMA auth_schema;

-- Move Billing & Monetization tables to billing_schema
ALTER TABLE saas_plan SET SCHEMA billing_schema;
ALTER TABLE subscription SET SCHEMA billing_schema;
ALTER TABLE invoice SET SCHEMA billing_schema;

-- Move Operational & IoT tables to ops_schema
ALTER TABLE tank SET SCHEMA ops_schema;
ALTER TABLE inventory SET SCHEMA ops_schema;
ALTER TABLE feeding_record SET SCHEMA ops_schema;
ALTER TABLE water_quality SET SCHEMA ops_schema;
ALTER TABLE harvest SET SCHEMA ops_schema;
ALTER TABLE maintenance SET SCHEMA ops_schema;

-- Move Marketplace tables to supplier_schema
ALTER TABLE national_supplier SET SCHEMA supplier_schema;

-- Move Strategic & Financial tables to strategic_schema
ALTER TABLE financial_transaction SET SCHEMA strategic_schema;

-- Move General & Notification tables to general_schema
ALTER TABLE notification SET SCHEMA general_schema;
ALTER TABLE approval_request SET SCHEMA general_schema;
