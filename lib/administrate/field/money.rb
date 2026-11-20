require "administrate/field/base"

module Administrate
  module Field
    # Currency amount, right-aligned with tabular digits and a muted unit.
    #   amount: Field::Money
    #   amount: Field::Money.with_options(unit: "USD", precision: 2)
    class Money < Base
      def unit = options.fetch(:unit, AdministrateThemeUi.config.currency_unit)
      def precision = options.fetch(:precision, 0)

      def self.searchable? = false
      def self.html_class = "number"

      # Shares the numeric column styling (right-aligned) with Field::Number.
      def html_class = "number"
    end
  end
end
