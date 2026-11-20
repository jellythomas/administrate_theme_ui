module Admin
  # Renders stock Administrate markup to exercise compat.css.
  class LegacyController < Admin::ApplicationController
    def index
      @companies = Company.limit(5)
    end
  end
end
