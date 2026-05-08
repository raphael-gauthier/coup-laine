-- src/infra/db/migrations/0007_rename_travel_fee_settings.sql
-- The bootstrap seed historically wrote 'bracket_km' and
-- 'travel_fee_euros_per_bracket', but the app has been reading
-- 'tour_bracket_km' and 'tour_fee_eur_per_bracket' since the travel-fees
-- rework. Carry over any user-set value into the current keys (only when
-- the current key isn't already populated) and drop the dead legacy rows.

INSERT OR IGNORE INTO `settings` (`key`, `value`)
SELECT 'tour_bracket_km', `value` FROM `settings` WHERE `key` = 'bracket_km';
--> statement-breakpoint

INSERT OR IGNORE INTO `settings` (`key`, `value`)
SELECT 'tour_fee_eur_per_bracket', `value` FROM `settings` WHERE `key` = 'travel_fee_euros_per_bracket';
--> statement-breakpoint

DELETE FROM `settings` WHERE `key` IN ('bracket_km', 'travel_fee_euros_per_bracket');
