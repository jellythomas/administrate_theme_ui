require_relative "lib/administrate_theme_ui/version"

Gem::Specification.new do |s|
  s.name        = "administrate_theme_ui"
  s.version     = AdministrateThemeUi::VERSION
  s.summary     = "Themeable, plug-and-play UI layer for Administrate"
  s.description = "Replaces Administrate's views and styles with two themes (Graphite, Ledger), per-user " \
                  "light/dark mode, KPI/chart/table/modal/pagination components and generators. " \
                  "Dashboards, fields, controllers and administrate:* generators keep working unchanged."
  s.authors     = ["Jelly Thomas"]
  s.homepage    = "https://github.com/jellythomas/administrate_theme_ui"
  s.license     = "MIT" # bundled fonts are SIL OFL 1.1, Chart.js is MIT (see README)
  s.files       = Dir["{app,lib,vendor}/**/*", "README.md", "CHANGELOG.md", "LICENSE"]
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 3.1"

  # Only GitHub Packages may receive `gem push` (never rubygems.org by accident).
  s.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/jellythomas"
  s.metadata["github_repo"] = "ssh://github.com/jellythomas/administrate_theme_ui"
  s.metadata["source_code_uri"] = "https://github.com/jellythomas/administrate_theme_ui"
  s.metadata["changelog_uri"] = "https://github.com/jellythomas/administrate_theme_ui/blob/main/CHANGELOG.md"
  s.metadata["rubygems_mfa_required"] = "true"

  s.add_dependency "administrate", ">= 1.0", "< 2"
  s.add_dependency "railties", ">= 7.0", "< 9"
  s.add_dependency "sprockets-rails", ">= 3.4", "< 4"
end
