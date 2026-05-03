-- R1.A migration: Flutter parity schema delta.
-- Hand-written because drizzle-kit prompts interactively for column renames.

PRAGMA foreign_keys=OFF;
--> statement-breakpoint

-- =============================================================
-- clients: drop email/first_name/last_name/notes; add is_banned,
-- needs_distance_recompute, marker_color_hex; add new indexes.
-- =============================================================

CREATE TABLE `__new_clients` (
	`id` text PRIMARY KEY NOT NULL,
	`display_name` text NOT NULL,
	`phones` text DEFAULT '[]' NOT NULL,
	`address_label` text,
	`address_city` text,
	`address_postcode` text,
	`latitude` real,
	`longitude` real,
	`is_waiting` integer DEFAULT 0 NOT NULL,
	`is_banned` integer DEFAULT 0 NOT NULL,
	`needs_distance_recompute` integer DEFAULT 0 NOT NULL,
	`last_shearing_date` text,
	`animal_counts` text DEFAULT '[]' NOT NULL,
	`marker_color_hex` text,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
INSERT INTO `__new_clients` (
	`id`, `display_name`, `phones`,
	`address_label`, `address_city`, `address_postcode`,
	`latitude`, `longitude`, `is_waiting`,
	`is_banned`, `needs_distance_recompute`,
	`last_shearing_date`, `animal_counts`, `marker_color_hex`,
	`created_at`, `updated_at`
)
SELECT
	`id`, `display_name`, `phones`,
	`address_label`, `address_city`, `address_postcode`,
	`latitude`, `longitude`, `is_waiting`,
	0, 0,
	`last_shearing_date`, `animal_counts`, NULL,
	`created_at`, `updated_at`
FROM `clients`;
--> statement-breakpoint
DROP TABLE `clients`;
--> statement-breakpoint
ALTER TABLE `__new_clients` RENAME TO `clients`;
--> statement-breakpoint
CREATE INDEX `clients_is_waiting_idx` ON `clients` (`is_waiting`);
--> statement-breakpoint
CREATE INDEX `clients_is_banned_idx` ON `clients` (`is_banned`);
--> statement-breakpoint
CREATE INDEX `clients_needs_recompute_idx` ON `clients` (`needs_distance_recompute`);
--> statement-breakpoint
CREATE INDEX `clients_last_shearing_idx` ON `clients` (`last_shearing_date`);
--> statement-breakpoint

-- =============================================================
-- species: drop color; add icon_key, archived_at.
-- =============================================================

CREATE TABLE `__new_species` (
	`id` text PRIMARY KEY NOT NULL,
	`label` text NOT NULL,
	`icon_key` text,
	`ordering` integer NOT NULL,
	`is_custom` integer DEFAULT 0 NOT NULL,
	`archived_at` text
);
--> statement-breakpoint
INSERT INTO `__new_species` (`id`, `label`, `icon_key`, `ordering`, `is_custom`, `archived_at`)
SELECT `id`, `label`, NULL, `ordering`, `is_custom`, NULL FROM `species`;
--> statement-breakpoint
DROP TABLE `species`;
--> statement-breakpoint
ALTER TABLE `__new_species` RENAME TO `species`;
--> statement-breakpoint

-- =============================================================
-- animal_categories: drop average_minutes_per_unit; add archived_at.
-- =============================================================

CREATE TABLE `__new_animal_categories` (
	`id` text PRIMARY KEY NOT NULL,
	`species_id` text NOT NULL,
	`label` text NOT NULL,
	`ordering` integer NOT NULL,
	`is_custom` integer DEFAULT 0 NOT NULL,
	`archived_at` text,
	FOREIGN KEY (`species_id`) REFERENCES `species`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
INSERT INTO `__new_animal_categories` (`id`, `species_id`, `label`, `ordering`, `is_custom`, `archived_at`)
SELECT `id`, `species_id`, `label`, `ordering`, `is_custom`, NULL FROM `animal_categories`;
--> statement-breakpoint
DROP TABLE `animal_categories`;
--> statement-breakpoint
ALTER TABLE `__new_animal_categories` RENAME TO `animal_categories`;
--> statement-breakpoint
CREATE INDEX `animal_categories_species_idx` ON `animal_categories` (`species_id`);
--> statement-breakpoint

-- =============================================================
-- prestations: rename price (real, euros) -> price_cents (integer);
-- add minutes, category_id, archived_at.
-- =============================================================

CREATE TABLE `__new_prestations` (
	`id` text PRIMARY KEY NOT NULL,
	`label` text NOT NULL,
	`price_cents` integer,
	`minutes` integer DEFAULT 0 NOT NULL,
	`category_id` text,
	`is_active` integer DEFAULT 1 NOT NULL,
	`archived_at` text,
	`ordering` integer NOT NULL,
	FOREIGN KEY (`category_id`) REFERENCES `animal_categories`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
INSERT INTO `__new_prestations` (`id`, `label`, `price_cents`, `minutes`, `category_id`, `is_active`, `archived_at`, `ordering`)
SELECT
	`id`, `label`,
	CASE WHEN `price` IS NULL THEN NULL ELSE CAST(ROUND(`price` * 100) AS INTEGER) END,
	0,
	NULL,
	`is_active`,
	NULL,
	`ordering`
FROM `prestations`;
--> statement-breakpoint
DROP TABLE `prestations`;
--> statement-breakpoint
ALTER TABLE `__new_prestations` RENAME TO `prestations`;
--> statement-breakpoint

-- =============================================================
-- tours: drop 'draft' status (migrate to 'planned'); add columns.
-- =============================================================

UPDATE `tours` SET `status` = 'planned' WHERE `status` = 'draft';
--> statement-breakpoint
ALTER TABLE `tours` ADD COLUMN `total_drive_seconds` integer;
--> statement-breakpoint
ALTER TABLE `tours` ADD COLUMN `total_revenue_cents` integer;
--> statement-breakpoint
ALTER TABLE `tours` ADD COLUMN `total_animals_count` integer;
--> statement-breakpoint
ALTER TABLE `tours` ADD COLUMN `total_travel_fee_cents` integer;
--> statement-breakpoint
ALTER TABLE `tours` ADD COLUMN `route_geometry` text;
--> statement-breakpoint
ALTER TABLE `tours` ADD COLUMN `notes` text;
--> statement-breakpoint
ALTER TABLE `tours` ADD COLUMN `completed_at` text;
--> statement-breakpoint

-- =============================================================
-- tour_stops: rename prestations -> planned_prestations; drop
-- arrival_time; add client_name_snapshot, arrival_minutes,
-- departure_minutes, fee_share_cents, actual_prestations.
-- =============================================================

CREATE TABLE `__new_tour_stops` (
	`id` text PRIMARY KEY NOT NULL,
	`tour_id` text NOT NULL,
	`client_id` text NOT NULL,
	`client_name_snapshot` text,
	`ordering` integer NOT NULL,
	`arrival_minutes` integer,
	`departure_minutes` integer,
	`estimated_minutes` integer,
	`fee_share_cents` integer,
	`planned_prestations` text DEFAULT '[]' NOT NULL,
	`actual_prestations` text,
	`notes` text,
	`completed_at` text,
	FOREIGN KEY (`tour_id`) REFERENCES `tours`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`client_id`) REFERENCES `clients`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
INSERT INTO `__new_tour_stops` (
	`id`, `tour_id`, `client_id`, `client_name_snapshot`, `ordering`,
	`arrival_minutes`, `departure_minutes`, `estimated_minutes`, `fee_share_cents`,
	`planned_prestations`, `actual_prestations`, `notes`, `completed_at`
)
SELECT
	`id`, `tour_id`, `client_id`, NULL, `ordering`,
	NULL, NULL, `estimated_minutes`, NULL,
	`prestations`, NULL, `notes`, `completed_at`
FROM `tour_stops`;
--> statement-breakpoint
DROP TABLE `tour_stops`;
--> statement-breakpoint
ALTER TABLE `__new_tour_stops` RENAME TO `tour_stops`;
--> statement-breakpoint
CREATE INDEX `tour_stops_tour_idx` ON `tour_stops` (`tour_id`);
--> statement-breakpoint
CREATE INDEX `tour_stops_client_idx` ON `tour_stops` (`client_id`);
--> statement-breakpoint

-- =============================================================
-- distance_matrix: add failed flag for retry logic.
-- =============================================================

ALTER TABLE `distance_matrix` ADD COLUMN `failed` integer DEFAULT 0 NOT NULL;
--> statement-breakpoint

PRAGMA foreign_keys=ON;
