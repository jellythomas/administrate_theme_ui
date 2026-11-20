module AdministrateThemeUi
  class Engine < ::Rails::Engine
    # Defined after Administrate::Engine, so our app/views is prepended later and
    # wins over Administrate's views. Host app views still win over ours.

    initializer "administrate_theme_ui.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.precompile += %w[
          administrate_theme_ui/application.css
          administrate_theme_ui/application.js
          administrate_theme_ui/chart.umd.js
          administrate_theme_ui/ibm-plex-sans-400.woff2 administrate_theme_ui/ibm-plex-sans-500.woff2 administrate_theme_ui/ibm-plex-sans-600.woff2
          administrate_theme_ui/ibm-plex-mono-400.woff2 administrate_theme_ui/ibm-plex-mono-500.woff2
          administrate_theme_ui/source-serif-4-400.woff2 administrate_theme_ui/source-serif-4-600.woff2
        ]
      end
    end

    config.to_prepare do
      Administrate::Engine.stylesheets.delete("administrate/application")
      Administrate::Engine.add_stylesheet("administrate_theme_ui/application") unless Administrate::Engine.stylesheets.include?("administrate_theme_ui/application")
      Administrate::Engine.add_javascript("administrate_theme_ui/application") unless Administrate::Engine.javascripts.include?("administrate_theme_ui/application")

      Administrate::ApplicationController.helper(AdministrateThemeUi::ComponentsHelper)
    end
  end
end
