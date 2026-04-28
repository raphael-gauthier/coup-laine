# Coupe-Laine — MVP Design

> Brittany sheep-shearer's daily companion: client management + tour planning + travel-cost split.

This spec is split into focused documents for readability. Read in order.

| # | Document | What's inside |
|---|---|---|
| 1 | [Overview](./01-overview.md) | Business context, problem, MVP scope, glossary |
| 2 | [Architecture](./02-architecture.md) | Stack, layered design, secret config |
| 3 | [Data model](./03-data-model.md) | SQLite tables, conventions |
| 4 | [User flows](./04-user-flows.md) | The seven core flows end-to-end |
| 5 | [Distance matrix](./05-distance-matrix.md) | Pre-computed road-distance lifecycle |
| 6 | [Error handling](./06-error-handling.md) | Network, data, business edge cases |
| 7 | [Testing](./07-testing.md) | What to test, what not to test |

## Conventions

- **Specs and code: English.** App UI: French.
- **Target platform:** Android only for MVP. Code stays portable for later iOS.
- **Today:** 2026-04-28. Author: Raphaël Gauthier.
