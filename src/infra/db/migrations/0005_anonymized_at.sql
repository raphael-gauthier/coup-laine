-- 0005 migration: add anonymized_at to clients.
-- Hand-written because drizzle-kit requires an interactive TTY for generate.

ALTER TABLE `clients` ADD COLUMN `anonymized_at` text;
