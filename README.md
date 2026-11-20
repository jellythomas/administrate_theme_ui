**Classification: PUBLIC**

# administrate_theme_ui

A UI layer for [Administrate](https://github.com/thoughtbot/administrate) 1.x that you add to an app with almost no setup. It replaces every Administrate view, layout and stylesheet with a themeable design system. Dashboards, fields, controllers, search, sorting, pagination, authorization and the `administrate:*` generators all work as before.

## Install

```ruby
# Gemfile
gem "administrate", "~> 1.0"
gem "administrate_theme_ui", git: "https://github.com/jellythomas/administrate_theme_ui.git", tag: "v0.1.1"
```

```sh
bundle install
rails g administrate_theme_ui:install        # creates config/initializers/administrate_theme_ui.rb
```

That's it. Every existing Administrate page now renders with the theme. Keep generating dashboards with `rails g administrate:dashboard Model` as usual.

> Views in the host app still take priority. Run `rails g administrate_theme_ui:install` and it lists the overriding files it finds (`app/views/admin/application/*`, `layouts/admin/*`). Delete or restyle each one to get the new look.

## Configuration

```ruby
AdministrateThemeUi.configure do |config|
  config.app_name = "Flex Admin"
  config.theme = :graphite               # :graphite | :ledger
  config.default_mode = :system          # :light | :dark | :system
  config.allow_user_theme_switch = true  # users may pick another theme locally
  config.navigation_groups = { "Finance" => %i[transactions repayments], "Accounts" => %i[companies users] }
  config.status_tones = { info: %w[sent_to_partner] }
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
| Toasts | Standard `flash[:notice]` / `flash[:alert]` messages become toasts that dismiss themselves |
| Modal | `atu_modal(id:, title:, description:, size: :sm/:md/:lg/:xl, footer:, static: false) { }` + `atu_modal_trigger("Open", id)`. Sizes are 400, 560, 720 and 960px. Footer: Cancel first, primary last. Becomes a bottom sheet on phones |
| Destructive confirm | `form: { data: { atu_confirm: "Loan #12 will be permanently deleted.", atu_confirm_title: "Delete loan?", atu_confirm_action: "Delete loan", atu_confirm_type: "LOAN-12" } }` on `button_to`, or `data-atu-confirm*` on a link. Cancel gets focus, clicking the backdrop doesn't dismiss it, and the optional `atu_confirm_type` requires typing that text first. JS: `AdministrateThemeUi.confirm({message:, title:, action:, expect:}, fn)` |
| Empty state | `atu_empty_state(title:, description:, icon:) { action }` |
| Filters | Generated from the dashboard's `COLLECTION_FILTERS` as tabs ("All" + one per filter); other search words are kept |
| Pagination | Bar under every table: rows-per-page selector, a "1–20 of 1,234" range, "Page [n] of N", and first/prev/next/last buttons (disabled at the ends) |
| Keyboard | `/` focuses search, Enter or Space opens a focused row, Esc closes dialogs |
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

The component specs follow published design systems. Pagination uses the table pattern from IBM Carbon, with accessibility rules from GitHub Primer. Modals follow the anatomy, button order and close behaviour of Carbon and Atlassian, and their motion timings come from Carbon. The destructive-confirm pattern (Cancel focused, type-to-confirm, a verb plus noun label) comes from Primer ConfirmationDialog and Vercel Geist. Toast timing follows Polaris (5s) and Carbon (errors stay until dismissed). Badge styles are based on Primer Label and Stripe Badge.

## Security note

Administrate passes `params[:per_page]` straight to Kaminari, and the rows-per-page selector uses that parameter. Cap it in the host app so nobody can request a huge page:

```ruby
# config/initializers/kaminari.rb
Kaminari.configure { |c| c.max_per_page = 100 }
```

## Extension points

To extend the layout, use `content_for(:atu_topbar)`, `:atu_topbar_end` (for a user menu or environment badge), `:atu_nav_top` or `:atu_nav_bottom`, along with Administrate's own `:header_middle`, `:header_last`, `:before_main`, `:main` and `:after_main`.

## Development

```sh
ruby -Ilib test/configuration_test.rb
cd test/dummy && bin/rails db:setup && bin/rails s -p 3999   # http://localhost:3999/admin/stats
cd test/e2e && npm i && node e2e.mjs            # 35 browser checks (themes, modal, confirm, pager, tabs…)
node shots.mjs ./shots                           # screenshots: both themes, light and dark, desktop/tablet/phone
```

`test/dummy` is an Administrate app with companies, loan requests, StatusBadge and Money fields, filters, validations and a stats dashboard. Use it to check the UI. The e2e scripts expect Chrome at the default macOS path.

## Third-party assets

IBM Plex Sans/Mono 5.3.0 and Source Serif 4 5.3.1 are bundled under the SIL Open Font License 1.1 (licence texts in `vendor/assets/fonts/administrate_theme_ui/`). Chart.js 4.4.1 is bundled under the MIT License (header kept in the file).

## Requirements

Requires Administrate 1.x, Rails 7 or later, and sprockets-rails. The CSS is plain and the JS is vanilla, so there is no Node or Tailwind build step. It works with Turbo (which Administrate 1.0 ships) and with plain page loads.

## License

MIT © Jelly Thomas. See `LICENSE`. Bundled third-party assets keep their own licences (see above).
