-- Migration: confirm ticket_history table exists
-- Run this once against your Supabase database via the SQL editor or psql.
-- Safe to run even if the table already exists (idempotent).

CREATE TABLE IF NOT EXISTS ticket_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  changed_by_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  field_name VARCHAR(100) NOT NULL,
  old_value TEXT,
  new_value TEXT,

  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ticket_history_ticket ON ticket_history(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_history_changed_at ON ticket_history(changed_at DESC);
