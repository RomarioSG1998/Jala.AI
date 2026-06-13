-- Drop foreign key constraints that cross bounded context/service boundaries
-- to facilitate modular database schema division and eventual microservice extraction.

ALTER TABLE subscription DROP CONSTRAINT fk_subscription_farm;
ALTER TABLE tank DROP CONSTRAINT fk_tank_farm;
ALTER TABLE inventory DROP CONSTRAINT fk_inventory_farm;
ALTER TABLE feeding_record DROP CONSTRAINT fk_feeding_farm;
ALTER TABLE water_quality DROP CONSTRAINT fk_water_quality_farm;
ALTER TABLE harvest DROP CONSTRAINT fk_harvest_farm;
ALTER TABLE maintenance DROP CONSTRAINT fk_maintenance_farm;
ALTER TABLE financial_transaction DROP CONSTRAINT fk_transaction_farm;
ALTER TABLE approval_request DROP CONSTRAINT fk_approval_farm;
ALTER TABLE approval_request DROP CONSTRAINT fk_approval_requester;
