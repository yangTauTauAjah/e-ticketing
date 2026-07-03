-- Migration: add OTP columns for self-service password reset
-- Run this once against your Supabase database via the SQL editor or psql.
-- Safe to run even if the columns already exist (idempotent).

ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_otp_hash VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_otp_expires_at TIMESTAMP;
