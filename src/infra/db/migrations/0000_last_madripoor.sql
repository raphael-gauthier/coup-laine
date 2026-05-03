CREATE TABLE `animal_categories` (
	`id` text PRIMARY KEY NOT NULL,
	`species_id` text NOT NULL,
	`label` text NOT NULL,
	`average_minutes_per_unit` real NOT NULL,
	`ordering` integer NOT NULL,
	`is_custom` integer DEFAULT 0 NOT NULL,
	FOREIGN KEY (`species_id`) REFERENCES `species`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `animal_categories_species_idx` ON `animal_categories` (`species_id`);--> statement-breakpoint
CREATE TABLE `clients` (
	`id` text PRIMARY KEY NOT NULL,
	`display_name` text NOT NULL,
	`first_name` text,
	`last_name` text,
	`phones` text DEFAULT '[]' NOT NULL,
	`email` text,
	`address_label` text,
	`address_city` text,
	`address_postcode` text,
	`latitude` real,
	`longitude` real,
	`is_waiting` integer DEFAULT 0 NOT NULL,
	`notes` text,
	`last_shearing_date` text,
	`animal_counts` text DEFAULT '[]' NOT NULL,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `clients_is_waiting_idx` ON `clients` (`is_waiting`);--> statement-breakpoint
CREATE INDEX `clients_last_shearing_idx` ON `clients` (`last_shearing_date`);--> statement-breakpoint
CREATE TABLE `distance_matrix` (
	`from_id` text NOT NULL,
	`to_id` text NOT NULL,
	`distance_km` real NOT NULL,
	`duration_minutes` integer NOT NULL,
	`fetched_at` text NOT NULL,
	PRIMARY KEY(`from_id`, `to_id`)
);
--> statement-breakpoint
CREATE TABLE `manual_history_entries` (
	`id` text PRIMARY KEY NOT NULL,
	`client_id` text NOT NULL,
	`date` text NOT NULL,
	`notes` text,
	`prestations` text DEFAULT '[]' NOT NULL,
	FOREIGN KEY (`client_id`) REFERENCES `clients`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `manual_history_client_idx` ON `manual_history_entries` (`client_id`);--> statement-breakpoint
CREATE TABLE `prestations` (
	`id` text PRIMARY KEY NOT NULL,
	`label` text NOT NULL,
	`price` real,
	`is_active` integer DEFAULT 1 NOT NULL,
	`ordering` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `settings` (
	`key` text PRIMARY KEY NOT NULL,
	`value` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `species` (
	`id` text PRIMARY KEY NOT NULL,
	`label` text NOT NULL,
	`color` text,
	`ordering` integer NOT NULL,
	`is_custom` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE `tour_stops` (
	`id` text PRIMARY KEY NOT NULL,
	`tour_id` text NOT NULL,
	`client_id` text NOT NULL,
	`ordering` integer NOT NULL,
	`arrival_time` text,
	`estimated_minutes` integer,
	`prestations` text DEFAULT '[]' NOT NULL,
	`notes` text,
	`completed_at` text,
	FOREIGN KEY (`tour_id`) REFERENCES `tours`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`client_id`) REFERENCES `clients`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `tour_stops_tour_idx` ON `tour_stops` (`tour_id`);--> statement-breakpoint
CREATE INDEX `tour_stops_client_idx` ON `tour_stops` (`client_id`);--> statement-breakpoint
CREATE TABLE `tours` (
	`id` text PRIMARY KEY NOT NULL,
	`scheduled_date` text NOT NULL,
	`departure_time` text NOT NULL,
	`base_lat` real NOT NULL,
	`base_lng` real NOT NULL,
	`status` text NOT NULL,
	`total_distance_km` real,
	`total_minutes` integer,
	`created_at` text NOT NULL,
	`updated_at` text NOT NULL
);
