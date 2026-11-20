require "administrate/engine"
require "administrate_theme_ui/version"
require "administrate_theme_ui/configuration"
require "administrate_theme_ui/engine"
require "administrate/field/status_badge"
require "administrate/field/money"

module AdministrateThemeUi
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end
  end
end
