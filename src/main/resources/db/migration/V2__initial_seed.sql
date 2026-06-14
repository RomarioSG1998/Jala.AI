-- ==========================================
-- INITIAL DATA SEEDS
-- ==========================================

-- 1. Insert Software Owner (SaaS Admin)
INSERT INTO auth_schema.global_user (id, name, email, password, account_type) 
VALUES ('11111111-1111-1111-1111-111111111111', 'SuperSaaS Admin', 'admin@aquasertao.com', crypt('admin123', gen_salt('bf')), 'SAAS_ADMIN');

-- 2. Insert SaaS Plans (Monetization)
INSERT INTO billing_schema.saas_plan (id, name, max_tanks, max_users, price_monthly) VALUES 
('22222222-2222-2222-2222-222222222221', 'Free', 3, 2, 0.00),
('22222222-2222-2222-2222-222222222222', 'Basic', 10, 5, 29.90),
('22222222-2222-2222-2222-222222222223', 'Professional', 30, 15, 59.90),
('22222222-2222-2222-2222-222222222224', 'Enterprise', 100, 50, 99.90);

-- 3. Insert an Approved National Supplier (B2B)
INSERT INTO supplier_schema.national_supplier (id, company_name, cnpj, supply_type, is_approved)
VALUES ('33333333-3333-3333-3333-333333333333', 'Northeast Feeds Ltd', '12.345.678/0001-99', 'Fish Feed', TRUE);

-- 4. Insert a Client User (Test Farmer)
INSERT INTO auth_schema.global_user (id, name, email, password, account_type)
VALUES ('44444444-4444-4444-4444-444444444444', 'John Doe', 'john@testfarm.com', crypt('password123', gen_salt('bf')), 'CLIENT');

-- 5. Create Tenant (Farm) for the Test Client
INSERT INTO auth_schema.farm_tenant (id, name, cnpj, owner_id)
VALUES ('55555555-5555-5555-5555-555555555555', 'Clear Waters Farm', '98.765.432/0001-11', '44444444-4444-4444-4444-444444444444');

-- 6. Link John as the Owner of his Farm
INSERT INTO auth_schema.user_farm_link (user_id, farm_id, access_role)
VALUES ('44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555', 'FARM_OWNER');

-- 7. Create an Active Subscription (Professional Plan) for John's Farm
INSERT INTO billing_schema.subscription (id, farm_id, plan_id, start_date, end_date, status)
VALUES ('66666666-6666-6666-6666-666666666666', '55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222223', CURRENT_DATE - INTERVAL '15 days', CURRENT_DATE + INTERVAL '350 days', 'ACTIVE');

-- 8. Add Test Tanks with Operational Metrics
INSERT INTO ops_schema.tank (id, farm_id, name, fish_species, fish_capacity, average_weight_g, mortality_count, next_harvest_date, status) VALUES
('77777777-7777-7777-7777-777777777777', '55555555-5555-5555-5555-555555555555', 'Nursery Tank 1', 'Tilapia', 5000, 520, 45, CURRENT_DATE + INTERVAL '25 days', 'ACTIVE'),
('77777777-7777-7777-7777-777777777778', '55555555-5555-5555-5555-555555555555', 'Grow-out Tank A', 'Tambaqui', 8000, 480, 120, CURRENT_DATE + INTERVAL '40 days', 'ACTIVE'),
('77777777-7777-7777-7777-777777777779', '55555555-5555-5555-5555-555555555555', 'Quarantine Tank', 'Tilapia', 2000, 210, 8, NULL, 'ACTIVE');

-- 9. Insert Inventory Items
INSERT INTO ops_schema.inventory (id, farm_id, item_name, quantity, unit, type) VALUES
('88888888-8888-8888-8888-888888888881', '55555555-5555-5555-5555-555555555555', 'Ração Inicial 2mm', 500.00, 'kg', 'Feed'),
('88888888-8888-8888-8888-888888888882', '55555555-5555-5555-5555-555555555555', 'Ração Engorda 6mm', 1200.00, 'kg', 'Feed'),
('88888888-8888-8888-8888-888888888883', '55555555-5555-5555-5555-555555555555', 'Vitamina C', 15.50, 'kg', 'Medicine'),
('88888888-8888-8888-8888-888888888884', '55555555-5555-5555-5555-555555555555', 'Rede de Arrasto', 2.00, 'unidades', 'Equipment'),
('88888888-8888-8888-8888-888888888885', '55555555-5555-5555-5555-555555555555', 'Teste de pH', 5.00, 'kits', 'Equipment');

-- 10. Insert Feeding Records
INSERT INTO ops_schema.feeding_record (id, farm_id, tank_id, user_id, feed_id, quantity, feeding_time) VALUES
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777', '44444444-4444-4444-4444-444444444444', '88888888-8888-8888-8888-888888888881', 35.50, CURRENT_TIMESTAMP - INTERVAL '6 hours'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777778', '44444444-4444-4444-4444-444444444444', '88888888-8888-8888-8888-888888888882', 52.00, CURRENT_TIMESTAMP - INTERVAL '2 hours');

-- 11. Insert Water Quality Logs
INSERT INTO ops_schema.water_quality (id, farm_id, tank_id, measurement_time, ph, temperature, dissolved_oxygen) VALUES
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777', CURRENT_TIMESTAMP - INTERVAL '2 days', 7.20, 26.50, 6.80),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777', CURRENT_TIMESTAMP - INTERVAL '1 day', 7.10, 26.80, 6.50),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777778', CURRENT_TIMESTAMP - INTERVAL '12 hours', 6.80, 27.20, 7.00),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777779', CURRENT_TIMESTAMP - INTERVAL '2 hours', 8.20, 25.50, 5.50);

-- 12. Insert Harvests
INSERT INTO ops_schema.harvest (id, farm_id, tank_id, date, quantity_kg, destination) VALUES
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777', CURRENT_DATE - INTERVAL '30 days', 1500.00, 'Mercado Central'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777778', CURRENT_DATE - INTERVAL '5 days', 2200.50, 'Frigorífico XYZ');

-- 13. Insert Maintenance Tasks
INSERT INTO ops_schema.maintenance (id, farm_id, tank_id, description, status, scheduled_date) VALUES
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777', 'Limpeza do filtro biológico', 'PENDING', CURRENT_DATE + INTERVAL '2 days'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777778', 'Troca da bomba de aeração', 'COMPLETED', CURRENT_DATE - INTERVAL '1 day'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777779', 'Inspeção estrutural da lona', 'PENDING', CURRENT_DATE - INTERVAL '5 days');

-- 14. Insert Initial Invoice
INSERT INTO billing_schema.invoice (id, subscription_id, amount, due_date, paid_date, status)
VALUES (uuid_generate_v4(), '66666666-6666-6666-6666-666666666666', 59.90, CURRENT_DATE + INTERVAL '30 days', NULL, 'PENDING');

-- 15. Insert Sample Financial Transactions
INSERT INTO strategic_schema.financial_transaction (id, farm_id, type, amount, transaction_date) VALUES
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', 'Income', 2200.50, CURRENT_TIMESTAMP - INTERVAL '5 days'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', 'Expense', 680.75, CURRENT_TIMESTAMP - INTERVAL '1 day');

-- 16. Insert Approval Request
INSERT INTO general_schema.approval_request (id, farm_id, requester_id, requested_action, status, request_date)
VALUES (uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', 'Solicitação para compra emergencial de ração', 'Pending', CURRENT_TIMESTAMP - INTERVAL '3 hours');

-- 17. Insert Notification
INSERT INTO general_schema.notification (id, target_user_id, type, message, is_read, created_at)
VALUES (uuid_generate_v4(), '44444444-4444-4444-4444-444444444444', 'ALERT', 'pH fora da faixa ideal no Quarantine Tank.', FALSE, CURRENT_TIMESTAMP - INTERVAL '2 hours');
