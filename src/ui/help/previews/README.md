# Help previews — maintenance convention

These components reproduce the **visual appearance** of real screens to be
embedded inside the contextual help sheets (`src/ui/help/sheets/*`).

They are **deliberately decoupled** from the real components: they don't
import the production code, they don't fetch data, they hardcode demo
content. This keeps the help sheets renderable without any DB / hooks /
auth state.

## Maintenance — when to update

When the corresponding real component undergoes a **visible** change
(layout, padding, badge style, color treatment, structural reorganisation),
update the demo to match. Minor token / spacing tweaks don't warrant
updates.

| Demo file | Mirrors |
| --- | --- |
| `client-card-demo.tsx` | `src/ui/components/client-card.tsx` |
| `client-filter-demo.tsx` | `src/ui/components/client-status-filter-dialog.tsx` |
| `tour-card-demo.tsx` | `src/ui/components/tour-card.tsx` |
| `tour-planning-demo.tsx` | tour stop rows in `app/(tabs)/tours/[id].tsx` (via `TourStopRow`) |
| `completion-row-demo.tsx` | `src/ui/components/stop-completion-editor.tsx` |
| `service-row-demo.tsx` | catalog row in `app/(tabs)/settings/services/index.tsx` |
| `status-row-demo.tsx` | status row in `app/(tabs)/settings/statuses.tsx` |
| `tour-stop-list-demo.tsx` | tour stop row in `app/(tabs)/tours/[id].tsx` |

## Why not reuse the real components

The real components depend on global hooks (`useDisplayedStatusMap`,
`useStatusRegistry`, etc.) that fetch from the DB. Wiring them with fake
data would require either invasive refactoring (extracting presentational
variants) or fake providers — neither earns the cost vs. maintaining a
small, isolated copy.

The cost we accept: visual drift between demo and real if updates are
forgotten. Mitigation: review this folder during any UI redesign sweep.
