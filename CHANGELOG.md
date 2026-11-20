# Changelog

## 0.2.0

- Navigation hooks: `config.navigation_resources` (e.g. role-filtered menus) and `config.navigation_pinned`.
- Partial hooks: `_user_menu`, `_index_actions`, `_body_end`; `atu_user_menu` helper (accessible `<details>` dropdown).
- `compat.css`: styles Administrate's stock markup (headers, buttons, legacy tables, show lists, forms,
  flashes, `#error_explanation`, Kaminari default pagination, jquery.modal) so customised apps fit the theme.
- Breadcrumb fallback "app / page title" for pages that set none.
- README: "How it works" and "Adopting in an app with customised views".

## 0.1.1

- Licensed under MIT (`LICENSE`).

## 0.1.0

- Graphite and Ledger themes, each with light/dark palettes; per-user theme/mode stored in localStorage.
- Full Administrate view layer: layout, sidebar, topbar with breadcrumbs, index (filter tabs, search, table,
  pagination bar), show, new/edit (sectioned form with inline errors), flashes as toasts.
- Components: KPI strip, sparkline, money, charts (Chart.js 4.4.1), distribution bar, badges, alerts,
  modal, destructive confirm (Cancel-focused, type-to-confirm), empty state.
- Fields: `Field::StatusBadge`, `Field::Money`.
- Generators: `administrate_theme_ui:install`, `:views`, `:page`.
- Security: `?per_page=` restricted to `config.per_page_options` (Administrate passes it unbounded).
- Fonts registered via FontFace API (Administrate 1.0's anchor-positioning polyfill breaks `@font-face` url()).
