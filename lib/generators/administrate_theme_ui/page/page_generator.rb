require "rails/generators/named_base"

module AdministrateThemeUi
  module Generators
    # rails g administrate_theme_ui:page stats  → Admin::StatsController + a dashboard view with stat cards and charts.
    class PageGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)
      class_option :namespace, default: "admin"

      def create_controller
        template "controller.rb", "app/controllers/#{ns}/#{file_name}_controller.rb"
      end

      def create_view
        template "index.html.erb", "app/views/#{ns}/#{file_name}/index.html.erb"
      end

      def add_route
        route %(namespace :#{ns} do\n  get "#{file_name}", to: "#{file_name}#index", as: :#{file_name}\nend)
      end

      private

      def ns = options[:namespace]
      def ns_class = ns.camelize
    end
  end
end
