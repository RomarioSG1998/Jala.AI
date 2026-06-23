ALTER TABLE strategic_schema.financial_transaction
ADD COLUMN category VARCHAR(100),
ADD COLUMN client_name VARCHAR(255),
ADD COLUMN fish_species VARCHAR(100),
ADD COLUMN quantity_kg NUMERIC(10, 2);
