module AdministrateThemeUi
  # Prepended into Administrate::ApplicationController.
  # Administrate passes params[:per_page] straight to Kaminari, so any visitor can
  # request an unbounded page size. Only the configured options are accepted.
  # A host controller that defines its own #records_per_page still wins.
  module ControllerExtensions
    private

    def records_per_page
      requested = params[:per_page].to_i
      options = AdministrateThemeUi.config.per_page_options
      options.include?(requested) ? requested : AdministrateThemeUi.config.default_per_page
    end
  end
end
