-- Migration V19: Add title column to notification table
ALTER TABLE general_schema.notification ADD COLUMN IF NOT EXISTS title VARCHAR(255);
