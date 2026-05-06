-- 0004 migration: travel fees rework.
-- - Rename tour_stops.fee_share_cents -> travel_fee_cents (preserve values).
-- - Drop tours.total_travel_fee_cents (now derived from stops).
-- - Add manual_history_entries.travel_fee_cents (nullable).
-- Hand-written because drizzle-kit prompts interactively for renames/drops.

PRAGMA foreign_keys=OFF;
--> statement-breakpoint

-- =============================================================
-- tour_stops: rename fee_share_cents -> travel_fee_cents.
-- =============================================================

ALTER TABLE `tour_stops` RENAME COLUMN `fee_share_cents` TO `travel_fee_cents`;
--> statement-breakpoint

-- =============================================================
-- tours: drop total_travel_fee_cents (derived from stops now).
-- SQLite supports DROP COLUMN since 3.35; expo-sqlite ships >= 3.45.
-- =============================================================

ALTER TABLE `tours` DROP COLUMN `total_travel_fee_cents`;
--> statement-breakpoint

-- =============================================================
-- manual_history_entries: add nullable travel_fee_cents.
-- =============================================================

ALTER TABLE `manual_history_entries` ADD COLUMN `travel_fee_cents` integer;
--> statement-breakpoint

PRAGMA foreign_keys=ON;
