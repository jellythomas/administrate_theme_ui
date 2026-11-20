# Changelog

## 0.1.0 — unreleased

- Graphite and Ledger themes, each with light/dark palettes; per-user theme/mode stored in localStorage.
- Full Administrate view layer: layout, sidebar, topbar with breadcrumbs, index (filter tabs, search, table,
  pagination bar), show, new/edit (sectioned form with inline errors), flashes as toasts.
- Components: KPI strip, sparkline, money, charts (Chart.js 4.4.1), distribution bar, badges, alerts,
  modal, destructive confirm (Cancel-focused, type-to-confirm), empty state.
- Fields: `Field::StatusBadge`, `Field::Money`.
- Generators: `administrate_theme_ui:install`, `:views`, `:page`.
- Security: `?per_page=` restricted to `config.per_page_options` (Administrate passes it unbounded).
- Fonts registered via FontFace API (Administrate 1.0's anchor-positioning polyfill breaks `@font-face` url()).
