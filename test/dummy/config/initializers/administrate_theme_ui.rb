AdministrateThemeUi.configure do |config|
  config.app_name = "Dummy Admin"
  # config.logo_path = "logo.svg"            # asset path; falls back to the app_name initial

  # Theme shipped to everyone: :slate (neutral, indigo) or :ocean (navy sidebar, teal)
  config.theme = :graphite

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

  # Demo of the navigation hooks: pinned link + an explicit resource list.
  config.navigation_pinned = -> { [["Overview", admin_stats_path]] }
  config.navigation_resources = -> { %w[companies loan_requests legacy] }
end
