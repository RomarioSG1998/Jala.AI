-- V5: Add operational fields to tank table for richer metrics
ALTER TABLE tank ADD COLUMN IF NOT EXISTS average_weight_g INTEGER DEFAULT 0;
ALTER TABLE tank ADD COLUMN IF NOT EXISTS mortality_count INTEGER DEFAULT 0;
ALTER TABLE tank ADD COLUMN IF NOT EXISTS next_harvest_date DATE;
ALTER TABLE tank ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'ACTIVE';

-- Update existing seed tanks with rich data
UPDATE tank SET average_weight_g = 520, mortality_count = 45, next_harvest_date = CURRENT_DATE + INTERVAL '25 days', status = 'ACTIVE'
WHERE id = '77777777-7777-7777-7777-777777777777';

UPDATE tank SET average_weight_g = 480, mortality_count = 120, next_harvest_date = CURRENT_DATE + INTERVAL '40 days', status = 'ACTIVE'
WHERE id = '77777777-7777-7777-7777-777777777778';

UPDATE tank SET average_weight_g = 210, mortality_count = 8, next_harvest_date = NULL, status = 'ACTIVE'
WHERE id = '77777777-7777-7777-7777-777777777779';
