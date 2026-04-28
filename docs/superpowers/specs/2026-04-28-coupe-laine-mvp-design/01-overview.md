# 1. Overview

## Business context

The user is a self-employed sheep shearer working in Brittany, France. He travels to clients' farms to shear their sheep and occasionally trim hooves. He has roughly 200 clients.

**Travel pricing rule.** He bills €8 per started 10 km bracket of road distance (e.g. 1–10 km → €8, 11–20 km → €16). When several clients are visited in the same tour, he splits this travel cost across them.

**Time pricing.** Shearing time averages 20 min per sheep but varies per client (some sheep are less docile).

## The problem

When a client phones to book a shearing, he wants to slot them into a day along with other waiting clients in the area. With 200 clients spread across rural Brittany, he can't reliably remember which other clients are also waiting and geographically close to the caller.

He needs an app that:

1. Shows him **all waiting clients within a chosen radius** of a "pivot" client he just selected.
2. Helps him **compose a tour** from those clients with a **suggested visit order** that minimises total drive time.
3. **Computes the travel-fee split** he should bill each client of the tour.
4. Tracks which clients have been shorn recently so the "waiting" pool stays accurate.

## MVP scope

**In:**

- Manual client management (~200 clients), entered gradually.
- French postal address with autocomplete + geocoding via [API Adresse / BAN](https://adresse.data.gouv.fr/api-doc/adresse).
- Manual `is_waiting` toggle per client (set when a client calls).
- Proximity search around a pivot client (configurable radius), shown as **list and map**.
- Tour composition with suggested optimal order.
- Hourly schedule per stop (departure time → estimated arrival per client).
- Travel-fee split using the user's specific formula (see [User flows §5](./04-user-flows.md#5-confirm-a-tour)).
- Tour completion auto-updates each client's last-shearing date and clears `is_waiting`.
- Local SQLite storage. Manual JSON export/import for backup.

**Out (deferred):**

- Cloud sync, multi-device, authentication.
- iOS build (Flutter code stays portable).
- Web/desktop builds.
- CSV/Excel client import.
- Invoice generation.
- Hoof-trimming as a structured field (handled via free-text notes).
- Per-client shearing pricing (uniform rate handled outside the app).
- Push notifications, reminders.
- Offline-first: app is **online-essentially**; user prepares tours the day before with connectivity.

## Glossary

| English term used in code/spec | French (UI) | Meaning |
|---|---|---|
| Client | Client | A farmer who hires the user |
| Tour | Tournée | A planned or completed sequence of client visits in one day |
| Tour stop | Étape de tournée | One client visit within a tour |
| Pivot client | Client pivot | The starting reference point of a proximity search |
| Waiting / pending | En attente | Client flagged as needing to be scheduled |
| Base | Base / domicile | The user's home address (single, configured once) |
| Travel fee | Frais de déplacement | Total distance-based fee for a tour |
| Fee split | Partage des frais | Per-client share of the travel fee |
| Bracket | Tranche | A 10 km billing increment (rounded up) |
| Shearing | Tonte | The act of shearing a client's sheep |
| Last shearing date | Dernière tonte | Date of the most recent completed tour for a client |
