-- ==========================================
-- INITIAL DATA SEEDS
-- ==========================================

-- 1. Insert Software Owner (SaaS Admin)
INSERT INTO global_user (id, name, email, password, account_type) 
VALUES ('11111111-1111-1111-1111-111111111111', 'SuperSaaS Admin', 'admin@aquasertao.com', 'secure_hash_password', 'SAAS_ADMIN');

-- 2. Insert SaaS Plans (Monetization)
INSERT INTO saas_plan (id, name, monthly_price) VALUES 
('22222222-2222-2222-2222-222222222221', 'Free', 0.00),
('22222222-2222-2222-2222-222222222222', 'Basic', 29.90),
('22222222-2222-2222-2222-222222222223', 'Professional', 59.90),
('22222222-2222-2222-2222-222222222224', 'Enterprise', 99.90);

-- 3. Insert an Approved National Supplier (B2B)
INSERT INTO national_supplier (id, company_name, cnpj, supply_type, is_approved)
VALUES ('33333333-3333-3333-3333-333333333333', 'Northeast Feeds Ltd', '12.345.678/0001-99', 'Fish Feed', TRUE);

-- 4. Insert a Client User (Test Farmer)
INSERT INTO global_user (id, name, email, password, account_type)
VALUES ('44444444-4444-4444-4444-444444444444', 'John Doe', 'john@testfarm.com', 'password123', 'CLIENT');

-- 5. Create Tenant (Farm) for the Test Client
INSERT INTO farm_tenant (id, owner_user_id, farm_name, location)
VALUES ('55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', 'Clear Waters Farm', 'Sertao PE');

-- 6. Link John as the Owner of his Farm
INSERT INTO user_farm_link (user_id, farm_id, access_role)
VALUES ('44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555', 'FARM_OWNER');

-- 7. Create an Active Subscription (Professional Plan) for John's Farm
INSERT INTO subscription (id, farm_id, plan_id, status, due_date)
VALUES ('66666666-6666-6666-6666-666666666666', '55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222223', 'Active', '2027-12-31');

-- 8. Add a Test Tank
INSERT INTO tank (id, farm_id, name, fish_species, fish_capacity)
VALUES ('77777777-7777-7777-7777-777777777777', '55555555-5555-5555-5555-555555555555', 'Nursery Tank 1', 'Tilapia', 5000);
