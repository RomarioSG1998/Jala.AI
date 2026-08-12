-- V18: Add active column to global_user table for user deactivation capability
ALTER TABLE auth_schema.global_user ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE;
