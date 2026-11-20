**Classification: PUBLIC**

# administrate_theme_ui

A UI layer for [Administrate](https://github.com/thoughtbot/administrate) 1.x that you add to an app with almost no setup. It replaces every Administrate view, layout and stylesheet with a themeable design system. Dashboards, fields, controllers, search, sorting, pagination, authorization and the `administrate:*` generators all work as before.

## Install

```ruby
# Gemfile
gem "administrate", "~> 1.0"
gem "administrate_theme_ui", git: "https://github.com/jellythomas/administrate_theme_ui.git", tag: "v0.3.0"
```

```sh
bundle install
rails g administrate_theme_ui:install        # creates config/initializers/administrate_theme_ui.rb
```

That's it. Every existing Administrate page now renders with the theme. Keep generating dashboards with `rails g administrate:dashboard Model` as usual.

> Views in the host app still take priority. Run `rails g administrate_theme_ui:install` and it lists the overriding files it finds (`app/views/admin/application/*`, `layouts/admin/*`). Delete or restyle each one to get the new look. See [Adopting in an app with customised views](#adopting-in-an-app-with-customised-views).

## How it works

The gem is a Rails engine loaded after Administrate's. It changes the presentation layer only and leaves your data, controllers and dashboards alone:

1. **Views.** The engine ships its own `app/views/administrate/application/*`, `layouts/administrate/application` and `fields/*` templates. Rails looks for templates in the app first, then in engines in reverse load order, so its views win over Administrate's while your app's views still win over both. Dashboards (`ATTRIBUTE_TYPES`, `COLLECTION_ATTRIBUTES`, ...) and field classes are read through Administrate's normal page objects, so nothing in them changes.
2. **Assets.** At boot it removes `administrate/application` from `Administrate::Engine.stylesheets`, adds its own stylesheet, and appends its JavaScript next to Administrate's. Administrate's JS (Turbo, Stimulus, Selectize, Trix) keeps working, and the gem restyles Selectize and Trix. Its own JS is plain vanilla with no build step. It also works without Turbo, for example when an app replaces Administrate's JS with jQuery/UJS.
3. **Theming.** Every colour, radius and font comes from CSS custom properties keyed on `<html data-theme="graphite|ledger" data-mode="light|dark">`. A small inline script in `<head>` reads the user's choice from `localStorage` and sets those attributes before first paint. Charts read the same variables and redraw when they change.
4. **Fonts.** The bundled fonts are registered with the JavaScript FontFace API instead of `@font-face`. Administrate 1.0's CSS anchor-positioning polyfill rewrites stylesheets into `blob:` URLs, which would break `url()` inside `@font-face`.
5. **Behaviour is Administrate's.** The gem adds no controller code and no interaction logic of its own. Row clicks use Administrate's Stimulus `table` controller. Search and `COLLECTION_FILTERS` use Administrate's search, with its filter help popover. Destroy uses Administrate's confirm message through `data-turbo-confirm` (and `data-confirm` for rails-ujs/jquery_ujs apps). Pagination is Administrate's Kaminari `paginate`, and flashes render inline as in Administrate. The only JavaScript hook it uses is `Turbo.setConfirmMethod`, so the confirm prompt appears in a styled dialog instead of `window.confirm`.
6. **Fields.** `Field::StatusBadge` and `Field::Money` are optional, ordinary Administrate fields with their own partials.

## Configuration

```ruby
AdministrateThemeUi.configure do |config|
  config.app_name = "Flex Admin"
  config.theme = :graphite               # :graphite | :ledger
  config.default_mode = :system          # :light | :dark | :system
  config.allow_user_theme_switch = true  # users may pick another theme locally
  config.navigation_groups = { "Finance" => %i[transactions repayments], "Accounts" => %i[companies users] }
  config.status_tones = { info: %w[sent_to_partner] }

  # Sidebar contents (both procs run inside the view, so helpers and ivars work):
  config.navigation_resources = -> { @sidebar_menus }          # e.g. a role-filtered list; default = all routed resources
  config.navigation_pinned    = -> { [["Dashboard", admin_root_path]] }
end
```

Each user chooses light, dark or system mode (and a theme, if allowed) in the topbar. The choice is saved in that browser's `localStorage` (`atu:prefs`) and applied before the page paints, so it never flashes the wrong theme. **System** mode follows the OS setting and updates when the OS setting changes.

### Themes

| Theme | Character |
|---|---|
| `graphite` | Cool monochrome. Ink-coloured primary buttons, one blue accent, IBM Plex Sans, pill badges with a dot, a light sidebar |
| `ledger` | Warm paper background. Serif (Source Serif 4) headings and figures, forest-green accent, a dark ink sidebar, square labels and small-caps table headers |

Each theme has a light and a dark palette, and both are made entirely of CSS custom properties (`app/assets/stylesheets/administrate_theme_ui/themes.css`). The fonts (IBM Plex Sans and Mono 5.3.0, Source Serif 4 5.3.1, all OFL-licensed) are bundled with the gem, so nothing is loaded from a CDN. The layout registers them through the FontFace API rather than `@font-face`. That's deliberate: Administrate 1.0's bundled CSS anchor-positioning polyfill rewrites stylesheets into `blob:` URLs, which breaks `url()` inside `@font-face`. To add a theme, copy one light/dark block pair, rename it, and add the name to `Configuration::THEMES`.

## Components

Helpers are available in every Administrate view, including custom pages under the admin namespace.

| Need | Helper |
|---|---|
| Page title + actions | `atu_page_header("Title", subtitle:) { buttons }` |
| Button / link button | `atu_button("Save", url = nil, variant: :primary/:secondary/:ghost/:danger/:danger_soft, icon:, size:)` |
| KPI strip | `atu_stat_grid { atu_stat_card(label:, value: atu_money(x), delta: 12.4, delta_label: "vs last month", spark: [..], link:, link_text:, hint:) }` renders one surface divided by hairlines, not separate cards |
| Money | `atu_money(amount)` shows `Rp 11.000.000.000` with a muted unit and tabular digits; set `currency_unit`, `delimiter` and `separator` in the config |
| Money column in a dashboard | `amount: Field::Money` (right-aligned; the form input shows a unit prefix) |
| Sparkline | `atu_sparkline([..])` is an inline SVG rendered on the server, with no JS |
| Breakdown | `atu_distribution({ "approved" => 12, ... })` draws a stacked bar plus a legend with counts and %. Statuses that share a tone get progressively lighter shades |
| Breadcrumbs | `atu_crumbs("Admin", ["Loans", loans_path], "Loan #12")` in the topbar. Index, show, new and edit pages set them automatically |
| Card / panel | `atu_card(title:, subtitle:, actions:, flush:, class: "atu-col-8") { }` inside `<div class="atu-grid">` |
| Charts | `atu_chart(type: :bar/:line/:area/:doughnut/:pie, labels:, datasets: [{ label:, data:, type: }], money: true, options: {})` |
| Status badge | `atu_badge("approved")` picks its tone automatically, or pass `tone: :warning` |
| Status column in a dashboard | `status: Field::StatusBadge.with_options(collection: %w[...], tones: { info: %w[...] })` |
| Alerts | `atu_alert("msg", tone: :success/:warning/:danger/:info, title:, dismissible: true)` |
| Flash messages | `flash[:notice]` / `flash[:alert]` render inline at the top of the page, styled by tone, persistent (as in Administrate) |
| Modal | `atu_modal(id:, title:, description:, size: :sm/:md/:lg/:xl, footer:, static: false) { }` + `atu_modal_trigger("Open", id)`. Sizes are 400, 560, 720 and 960px. Footer: Cancel first, primary last. Becomes a bottom sheet on phones |
| Destroy confirm | Same as Administrate: `data: { turbo_confirm: t("administrate.actions.confirm") }`. With Turbo, the prompt shows in a styled dialog (Cancel focused, Esc cancels); without Turbo, rails-ujs/jquery_ujs use `data-confirm` |
| Empty state | `atu_empty_state(title:, description:, icon:) { action }` |
| Filters | Administrate's search syntax (`rejected:`, `status:active`) from the dashboard's `COLLECTION_FILTERS`, with Administrate's help popover listing them |
| Pagination | Administrate's Kaminari `paginate` (numbered pages, first/prev/next/last), styled, under each table with a "1–20 of 1,234" range. `?per_page=` works as in Administrate |
| Keyboard | As in Administrate: Enter/Space on a focused row opens it; Esc closes dialogs |
| Inline form errors | Built in: each invalid field shows its own message plus a summary at the top |
| Icons | `atu_icon("wallet")`. The list of available names is in `_icons.html.erb` |

Charts use the bundled Chart.js 4.4.1, which loads only on pages that call `atu_chart`. Chart colours follow the active theme and redraw when the user switches theme or mode. For JS hooks, `window.AdministrateThemeUi` exposes `openModal(id)`, `confirm(msg, fn)` and `renderCharts()`.

## Generators

```sh
rails g administrate_theme_ui:install                       # initializer + report of host overrides
rails g administrate_theme_ui:page stats                    # Admin::StatsController + KPI/chart dashboard + route
rails g administrate_theme_ui:views                         # copy all themed views for customisation
rails g administrate_theme_ui:views index form --namespace=admin/companies   # per-resource override
```

Custom pages without a dashboard class (for example `get "stats"`) appear in the sidebar automatically.

## Design references

The visual specs follow published design systems. Pagination styling follows the accessibility rules of GitHub Primer. Modals follow the anatomy, button order and close behaviour of Carbon and Atlassian, and their motion timings come from Carbon. The confirm dialog focuses Cancel first, following Primer ConfirmationDialog. Badge styles are based on Primer Label and Stripe Badge.

## Security note

Administrate passes `params[:per_page]` straight to Kaminari, so anyone can request a very large page. The gem keeps Administrate's behaviour, so cap it in your app:

```ruby
# config/initializers/kaminari.rb
Kaminari.configure { |c| c.max_per_page = 100 }
```

The gem only changes how buttons and links look. Whether a New, Edit or Delete button shows is still decided by Administrate's `accessible_action?`, which you wire to your policy library by overriding `authorized_action?` in your admin `ApplicationController`. Your controllers keep enforcing authorization either way.

## Extension points

**Partial hooks.** Override any of these in your admin namespace, for example `app/views/admin/application/_user_menu.html.erb`. Each one renders nothing by default.

| Partial | Rendered | Typical use |
|---|---|---|
| `_user_menu` | topbar, right | `atu_user_menu(name: current_admin.name, detail: current_admin.role, links: [["Sign out", sign_out_path]])` |
| `_index_actions` | index page header, next to "New" (locals: `page`, `resources`) | Export button, bulk actions |
| `_body_end` | end of `<body>` | app-wide modals, scripts that need the DOM |

**content_for slots.** `:atu_breadcrumbs` (or `atu_crumbs(...)`), `:atu_topbar`, `:atu_topbar_end`, `:atu_nav_top`, `:atu_nav_bottom`, plus Administrate's own `:header_middle`, `:header_last`, `:before_main`, `:main`, `:after_main` and `:javascript`.

## Adopting in an app with customised views

Most real admins have years of custom Administrate views. You don't have to rewrite them:

- **Compat stylesheet.** Pages that still use Administrate's stock markup are styled by the theme: `main-content__header`/`__page-title`/`__body`, `button` (`--alt`, `--danger`), legacy tables (`cell-label`/`cell-data`), `dl > .attribute-label/.attribute-data`, `form .field-unit`, `form-actions`, `flash`/`flash-error`, `#error_explanation`, Kaminari's default `nav.pagination`, and jquery.modal. They follow the theme in light and dark mode.
- **Global overrides.** Look at each file in `app/views/<namespace>/application/` and `layouts/<namespace>/`. Delete the ones that are only visual. Move behaviour into hooks: user menu → `_user_menu`, extra header buttons → `_index_actions`, app-wide modals → `_body_end`, role-filtered menus → `config.navigation_resources`.
- **Old theme scripts.** Remove any earlier theme script that writes `data-theme` on `<html>`; it will fight the gem's.
- **Breadcrumbs.** Pages that set no breadcrumbs get "app name / page title" automatically.

## Development

```sh
ruby -Ilib test/configuration_test.rb
cd test/dummy && bin/rails db:setup && bin/rails s -p 3999   # http://localhost:3999/admin/stats
cd test/e2e && npm i && node e2e.mjs            # browser checks (themes, Administrate behaviour, pager, confirm…); NO_TURBO=1 for jQuery/UJS hosts
node shots.mjs ./shots                           # screenshots: both themes, light and dark, desktop/tablet/phone
```

`test/dummy` is an Administrate app with companies, loan requests, StatusBadge and Money fields, filters, validations and a stats dashboard. Use it to check the UI. The e2e scripts expect Chrome at the default macOS path.

## Third-party assets

IBM Plex Sans/Mono 5.3.0 and Source Serif 4 5.3.1 are bundled under the SIL Open Font License 1.1 (licence texts in `vendor/assets/fonts/administrate_theme_ui/`). Chart.js 4.4.1 is bundled under the MIT License (header kept in the file).

## Requirements

Requires Administrate 1.x, Rails 7 or later, and sprockets-rails. The CSS is plain and the JS is vanilla, so there is no Node or Tailwind build step. It works with Turbo (which Administrate 1.0 ships) and with plain page loads.

## License

MIT © Jelly Thomas. See `LICENSE`. Bundled third-party assets keep their own licences (see above).
