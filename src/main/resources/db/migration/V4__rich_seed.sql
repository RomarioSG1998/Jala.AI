-- ==========================================
-- RICH DATA SEEDS FOR TESTING (Post-V3 Schema)
-- ==========================================

-- We already have Farm: 55555555-5555-5555-5555-555555555555
-- We already have Tank 1: 77777777-7777-7777-7777-777777777777

-- 1. Insert More Tanks
INSERT INTO tank (id, farm_id, name, fish_species, fish_capacity) VALUES 
('77777777-7777-7777-7777-777777777778', '55555555-5555-5555-5555-555555555555', 'Grow-out Tank A', 'Tambaqui', 8000),
('77777777-7777-7777-7777-777777777779', '55555555-5555-5555-5555-555555555555', 'Quarantine Tank', 'Tilapia', 2000);

-- 2. Insert Water Quality Logs
INSERT INTO water_quality (id, farm_id, tank_id, measurement_time, ph, temperature, dissolved_oxygen) VALUES
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777', CURRENT_TIMESTAMP - INTERVAL '2 days', 7.2, 26.5, 6.8),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777', CURRENT_TIMESTAMP - INTERVAL '1 days', 7.1, 26.8, 6.5),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777778', CURRENT_TIMESTAMP - INTERVAL '12 hours', 6.8, 27.2, 7.0),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777779', CURRENT_TIMESTAMP - INTERVAL '2 hours', 8.2, 25.5, 5.5); -- Warning pH

-- 3. Insert Inventory Items
INSERT INTO inventory (id, farm_id, item_name, quantity, unit, type) VALUES
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', 'Ração Inicial 2mm', 500.00, 'kg', 'Feed'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', 'Ração Engorda 6mm', 1200.00, 'kg', 'Feed'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', 'Vitamina C', 15.50, 'kg', 'Medicine'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', 'Rede de Arrasto', 2.00, 'unidades', 'Equipment'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', 'Teste de pH', 5.00, 'kits', 'Equipment');

-- 4. Insert Harvests
INSERT INTO harvest (id, farm_id, tank_id, date, quantity_kg, destination) VALUES
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777', CURRENT_DATE - INTERVAL '30 days', 1500.00, 'Mercado Central'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777778', CURRENT_DATE - INTERVAL '5 days', 2200.50, 'Frigorífico XYZ');

-- 5. Insert Maintenance Tasks
INSERT INTO maintenance (id, farm_id, tank_id, description, status, scheduled_date) VALUES
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777', 'Limpeza do filtro biológico', 'PENDING', CURRENT_DATE + INTERVAL '2 days'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777778', 'Troca da bomba de aeração', 'COMPLETED', CURRENT_DATE - INTERVAL '1 days'),
(uuid_generate_v4(), '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777779', 'Inspeção estrutural da lona', 'PENDING', CURRENT_DATE - INTERVAL '5 days'); -- Overdue
