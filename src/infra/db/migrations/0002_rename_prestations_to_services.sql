-- R2 migration: rename `prestations` table to `services` and rename
-- the *_prestations columns in tour_stops + manual_history_entries.
-- Hand-written because drizzle-kit prompts interactively for renames.

PRAGMA foreign_keys=OFF;
--> statement-breakpoint

ALTER TABLE `prestations` RENAME TO `services`;
--> statement-breakpoint

ALTER TABLE `tour_stops` RENAME COLUMN `planned_prestations` TO `planned_services`;
--> statement-breakpoint

ALTER TABLE `tour_stops` RENAME COLUMN `actual_prestations` TO `actual_services`;
--> statement-breakpoint

ALTER TABLE `manual_history_entries` RENAME COLUMN `prestations` TO `services`;
--> statement-breakpoint

PRAGMA foreign_keys=ON;
