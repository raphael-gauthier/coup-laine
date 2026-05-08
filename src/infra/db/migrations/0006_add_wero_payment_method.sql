-- src/infra/db/migrations/0006_add_wero_payment_method.sql
-- Adds Wero to the default payment methods for users whose DB was already
-- seeded by 0003_payment_methods. Fresh installs get Wero from the bootstrap
-- seed in src/infra/db/bootstrap.ts.

INSERT OR IGNORE INTO `payment_methods` (`id`, `label`, `is_active`, `archived_at`, `ordering`) VALUES
	('pm-wero', 'Wero', 1, NULL, 5);
