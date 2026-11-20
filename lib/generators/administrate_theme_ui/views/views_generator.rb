require "rails/generators/base"

module AdministrateThemeUi
  module Generators
    # rails g administrate_theme_ui:views                → copy every themed view for full customisation
    # rails g administrate_theme_ui:views index show     → copy only those templates/partials
    # rails g administrate_theme_ui:views --namespace=admin/companies index
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../app/views", __dir__)
      argument :names, type: :array, default: [], banner: "view_or_partial ..."
      class_option :namespace, default: "administrate/application", desc: "Target view directory (e.g. admin/companies)"

      def copy_views
        Dir[File.join(self.class.source_root, "administrate/application/*.erb")].sort.each do |path|
          file = File.basename(path)
          next if names.any? && !names.include?(file.sub(/\A_/, "").sub(/\.html\.erb\z/, ""))

          copy_file "administrate/application/#{file}", "app/views/#{options[:namespace]}/#{file}"
        end
        copy_file "layouts/administrate/application.html.erb", "app/views/layouts/administrate/application.html.erb" if names.empty? || names.include?("layout")
      end
    end
  end
end
