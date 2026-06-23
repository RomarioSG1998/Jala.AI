ALTER TABLE ops_schema.water_quality
ADD COLUMN ammonia NUMERIC(5, 2),
ADD COLUMN nitrite NUMERIC(5, 2),
ADD COLUMN alkalinity NUMERIC(6, 2),
ADD COLUMN hardness NUMERIC(6, 2),
ADD COLUMN solids NUMERIC(6, 2);
