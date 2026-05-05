-- src/infra/db/migrations/0003_payment_methods.sql
-- Adds payment_methods table, payment columns on tour_stops and
-- manual_history_entries, seeds default methods, and backfills
-- pre-feature rows so they don't appear as outstanding.

PRAGMA foreign_keys=OFF;
--> statement-breakpoint

CREATE TABLE `payment_methods` (
	`id` text PRIMARY KEY NOT NULL,
	`label` text NOT NULL,
	`is_active` integer DEFAULT 1 NOT NULL,
	`archived_at` text,
	`ordering` integer NOT NULL
);
--> statement-breakpoint

ALTER TABLE `tour_stops` ADD COLUMN `payment_method_id` text REFERENCES `payment_methods`(`id`);
--> statement-breakpoint
ALTER TABLE `tour_stops` ADD COLUMN `payment_method_label_snapshot` text;
--> statement-breakpoint
ALTER TABLE `tour_stops` ADD COLUMN `is_paid` integer DEFAULT 0 NOT NULL;
--> statement-breakpoint
ALTER TABLE `tour_stops` ADD COLUMN `paid_at` text;
--> statement-breakpoint
CREATE INDEX `tour_stops_is_paid_idx` ON `tour_stops` (`is_paid`);
--> statement-breakpoint

ALTER TABLE `manual_history_entries` ADD COLUMN `payment_method_id` text REFERENCES `payment_methods`(`id`);
--> statement-breakpoint
ALTER TABLE `manual_history_entries` ADD COLUMN `payment_method_label_snapshot` text;
--> statement-breakpoint
ALTER TABLE `manual_history_entries` ADD COLUMN `is_paid` integer DEFAULT 0 NOT NULL;
--> statement-breakpoint
ALTER TABLE `manual_history_entries` ADD COLUMN `paid_at` text;
--> statement-breakpoint
CREATE INDEX `manual_history_is_paid_idx` ON `manual_history_entries` (`is_paid`);
--> statement-breakpoint

INSERT OR IGNORE INTO `payment_methods` (`id`, `label`, `is_active`, `archived_at`, `ordering`) VALUES
	('pm-cash', 'Espèces', 1, NULL, 1),
	('pm-check', 'Chèque', 1, NULL, 2),
	('pm-transfer', 'Virement', 1, NULL, 3),
	('pm-card', 'Carte bancaire', 1, NULL, 4);
--> statement-breakpoint

UPDATE `tour_stops` SET `is_paid` = 1, `paid_at` = `completed_at` WHERE `completed_at` IS NOT NULL;
--> statement-breakpoint
UPDATE `manual_history_entries` SET `is_paid` = 1, `paid_at` = `date`;
--> statement-breakpoint

PRAGMA foreign_keys=ON;
