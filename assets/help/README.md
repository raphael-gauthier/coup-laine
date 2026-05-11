# Help screenshots

This folder contains the static screenshots embedded in the contextual
help sheets (`src/ui/help/sheets/help-sheet-*.tsx`).

## Files expected

Each capture has a `-light` and a `-dark` variant. The sheet picks the
right one at runtime via `useResolvedColorScheme()`.

| File | Sheet | Caption key |
| --- | --- | --- |
| `clients-list-light.webp` / `clients-list-dark.webp` | help-sheet-clients | help.clients.caption_list |
| `clients-filter-light.webp` / `clients-filter-dark.webp` | help-sheet-clients | help.clients.caption_filter |
| `tours-list-light.webp` / `tours-list-dark.webp` | help-sheet-tours | help.tours.caption_list |
| `tours-planning-light.webp` / `tours-planning-dark.webp` | help-sheet-tours | help.tours.caption_planning |
| `completion-main-light.webp` / `completion-main-dark.webp` | help-sheet-completion | help.completion.caption_main |

## How to capture

1. Run the app on a real device (or emulator) with a populated DB so
   the screens look realistic. A handful of clients with addresses,
   one or two planned tours, and one in-progress completion is enough.
2. For each row in the table above:
   - Switch the device theme to light. Open the corresponding screen.
     Take a screenshot with the device's native screenshot shortcut.
   - Switch to dark theme. Take the same screenshot again.
3. Crop tightly around the screen content (no status bar / nav bar).
4. Resize to ~800px wide.
5. Convert to `.webp` (e.g. with `cwebp -q 80 input.png -o output.webp`
   or via an online tool).
6. Drop the file in this folder using the exact filename from the
   table above.

## Maintenance

Re-capture whenever the corresponding screen has a visible UI change
that meaningfully alters what the screenshot conveys. Minor token /
spacing tweaks don't warrant a refresh.
