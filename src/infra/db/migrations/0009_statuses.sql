CREATE TABLE `statuses` (
  `id` text PRIMARY KEY NOT NULL,
  `kind` text NOT NULL,
  `system_key` text,
  `label` text NOT NULL,
  `color_light` text NOT NULL,
  `color_dark` text NOT NULL,
  `sort_order` integer NOT NULL,
  `created_at` text NOT NULL
);
--> statement-breakpoint
CREATE INDEX `statuses_kind_idx` ON `statuses` (`kind`);
--> statement-breakpoint
CREATE INDEX `statuses_system_key_idx` ON `statuses` (`system_key`);
--> statement-breakpoint
ALTER TABLE `clients` ADD COLUMN `manual_status_id` text REFERENCES `statuses`(`id`) ON DELETE SET NULL;
--> statement-breakpoint
CREATE INDEX `clients_manual_status_id_idx` ON `clients` (`manual_status_id`);
--> statement-breakpoint
INSERT INTO statuses (id, kind, system_key, label, color_light, color_dark, sort_order, created_at)
VALUES
  ('sys_default',   'system', 'default',   'Par défaut',        '#94A3B8', '#64748B', 10, '2026-05-08T00:00:00.000Z'),
  ('sys_waiting',   'system', 'waiting',   'En attente de RDV', '#C88226', '#DC9E4E', 20, '2026-05-08T00:00:00.000Z'),
  ('sys_scheduled', 'system', 'scheduled', 'Planifié',          '#A1602F', '#C68A58', 30, '2026-05-08T00:00:00.000Z'),
  ('sys_done',      'system', 'done',      'Réalisé',           '#5C7548', '#98B282', 40, '2026-05-08T00:00:00.000Z'),
  ('sys_noAnimals', 'system', 'noAnimals', 'Sans animaux',      '#EAE0D3', '#302820', 50, '2026-05-08T00:00:00.000Z'),
  ('sys_banned',    'system', 'banned',    'Banni',             '#B23832', '#DC605A', 60, '2026-05-08T00:00:00.000Z');
--> statement-breakpoint
UPDATE statuses SET color_light = (SELECT value FROM settings WHERE key = 'marker_default_color'),
                    color_dark  = (SELECT value FROM settings WHERE key = 'marker_default_color')
  WHERE system_key = 'default'   AND EXISTS (SELECT 1 FROM settings WHERE key = 'marker_default_color');
--> statement-breakpoint
UPDATE statuses SET color_light = (SELECT value FROM settings WHERE key = 'marker_waiting_color'),
                    color_dark  = (SELECT value FROM settings WHERE key = 'marker_waiting_color')
  WHERE system_key = 'waiting'   AND EXISTS (SELECT 1 FROM settings WHERE key = 'marker_waiting_color');
--> statement-breakpoint
UPDATE statuses SET color_light = (SELECT value FROM settings WHERE key = 'marker_scheduled_color'),
                    color_dark  = (SELECT value FROM settings WHERE key = 'marker_scheduled_color')
  WHERE system_key = 'scheduled' AND EXISTS (SELECT 1 FROM settings WHERE key = 'marker_scheduled_color');
--> statement-breakpoint
UPDATE statuses SET color_light = (SELECT value FROM settings WHERE key = 'marker_done_color'),
                    color_dark  = (SELECT value FROM settings WHERE key = 'marker_done_color')
  WHERE system_key = 'done'      AND EXISTS (SELECT 1 FROM settings WHERE key = 'marker_done_color');
--> statement-breakpoint
UPDATE statuses SET color_light = (SELECT value FROM settings WHERE key = 'marker_no_animals_color'),
                    color_dark  = (SELECT value FROM settings WHERE key = 'marker_no_animals_color')
  WHERE system_key = 'noAnimals' AND EXISTS (SELECT 1 FROM settings WHERE key = 'marker_no_animals_color');
--> statement-breakpoint
UPDATE statuses SET color_light = (SELECT value FROM settings WHERE key = 'marker_banned_color'),
                    color_dark  = (SELECT value FROM settings WHERE key = 'marker_banned_color')
  WHERE system_key = 'banned'    AND EXISTS (SELECT 1 FROM settings WHERE key = 'marker_banned_color');
--> statement-breakpoint
DELETE FROM settings WHERE key IN (
  'marker_default_color', 'marker_waiting_color', 'marker_scheduled_color',
  'marker_done_color', 'marker_no_animals_color', 'marker_banned_color'
);
