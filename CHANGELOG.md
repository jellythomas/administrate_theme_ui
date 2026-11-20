# Changelog

## 0.3.0

Behaviour now follows Administrate exactly; the gem only changes presentation.

- Destroy: Administrate's `data-turbo-confirm` message (plus `data-confirm` for rails-ujs/jquery_ujs);
  the Turbo confirm is shown in a styled dialog via `Turbo.setConfirmMethod`. Removed custom
  confirm titles/labels and type-to-confirm.
- Row click: Administrate's Stimulus `table` controller (custom JS handler removed). Row destroy is a
  link with Rails method/confirm attributes so the controller doesn't treat it as a row click.
- Filters: Administrate's search syntax and filter help popover (tabs removed).
- Pagination: Administrate's Kaminari `paginate`, styled (rows-per-page selector and page jump removed).
- Flashes: inline and persistent (toasts removed).
- Removed: `?per_page=` clamp (documented a Kaminari cap instead), `/` search shortcut, form Cancel link.
- Fixed: helpers accidentally dropped in 0.2.0 (`atu_chart`, `atu_alert`, `atu_modal`,
  `atu_modal_trigger`, `atu_empty_state`) restored; guarded by `test/helper_api_test.rb`.

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
