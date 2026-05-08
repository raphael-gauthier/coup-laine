PRAGMA foreign_keys=OFF;
--> statement-breakpoint

CREATE TABLE __new_tours (
  id text PRIMARY KEY NOT NULL,
  scheduled_date text,
  departure_time text,
  title text,
  base_lat real NOT NULL,
  base_lng real NOT NULL,
  status text NOT NULL,
  total_distance_km real,
  total_drive_seconds integer,
  total_minutes integer,
  total_revenue_cents integer,
  total_animals_count integer,
  route_geometry text,
  notes text,
  completed_at text,
  created_at text NOT NULL,
  updated_at text NOT NULL
);
--> statement-breakpoint

INSERT INTO __new_tours
SELECT
  id, scheduled_date, departure_time,
  NULL,
  base_lat, base_lng, status,
  total_distance_km, total_drive_seconds, total_minutes,
  total_revenue_cents, total_animals_count,
  route_geometry, notes, completed_at, created_at, updated_at
FROM tours;
--> statement-breakpoint

DROP TABLE tours;
--> statement-breakpoint

ALTER TABLE __new_tours RENAME TO tours;
--> statement-breakpoint

PRAGMA foreign_keys=ON;
