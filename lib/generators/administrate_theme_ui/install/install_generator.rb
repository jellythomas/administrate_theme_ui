require "rails/generators/base"

module AdministrateThemeUi
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      desc "Creates the administrate_theme_ui initializer. Run `rails g administrate:install` first if Administrate is not set up."

      def create_initializer
        template "initializer.rb", "config/initializers/administrate_theme_ui.rb"
      end

      def report_overrides
        overrides = Dir[File.join(destination_root, "app/views/{admin,administrate}/application/*.erb")] +
                    Dir[File.join(destination_root, "app/views/layouts/{admin,administrate}/*.erb")]
        return if overrides.empty?

        say "\nThese host views override the theme and will keep the old look until removed or restyled:", :yellow
        overrides.each { |f| say "  #{f.delete_prefix("#{destination_root}/")}" }
      end
    end
  end
end
