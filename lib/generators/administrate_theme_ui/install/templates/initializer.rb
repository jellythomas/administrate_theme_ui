AdministrateThemeUi.configure do |config|
  config.app_name = "<%= Rails.application.class.module_parent_name.titleize %> Admin"
  # config.logo_path = "logo.svg"            # asset path; falls back to the app_name initial

  # Theme shipped to everyone:
  #   :graphite — cool monochrome, ink buttons, IBM Plex, single blue accent
  #   :ledger   — warm paper, serif headings/figures, forest-green accent, ink sidebar
  config.theme = :graphite

  # Money formatting for atu_money / Field::Money-style displays
  config.currency_unit = "Rp"
  config.delimiter = "."
  config.separator = ","

  # Page sizes users may pick. Any other ?per_page= value falls back to the default,
  # so nobody can request an unbounded page.
  config.per_page_options = [10, 20, 50, 100]
  config.default_per_page = 20

  # Default colour mode until a user picks one: :light, :dark or :system.
  # Each user's choice (and theme, if switching is allowed) is kept in their browser's localStorage.
  config.default_mode = :system
  config.allow_user_theme_switch = true

  # Sidebar grouping by resource (route) name. Unlisted resources go to "Resources".
  # config.navigation_groups = {
  #   "Finance"  => %i[transactions repayments],
  #   "Accounts" => %i[companies users]
  # }

  # Extra status → tone mappings for atu_badge / Field::StatusBadge.
  # Tones: :success, :warning, :danger, :info, :neutral, :accent
  # config.status_tones = { info: %w[sent_to_partner], success: %w[approved_by_partner] }
end
