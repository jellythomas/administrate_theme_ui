require "administrate/field/base"

module Administrate
  module Field
    # Renders a value as a coloured status pill.
    #   status: Field::StatusBadge
    #   status: Field::StatusBadge.with_options(tones: { success: %w[paid] }, collection: %w[draft paid])
    class StatusBadge < Base
      def tone
        custom = options.fetch(:tones, {}).find { |_tone, values| Array(values).map(&:to_s).include?(data.to_s) }
        custom ? custom.first : AdministrateThemeUi.config.tone_for(data)
      end

      def label
        data.to_s.humanize
      end

      def selectable_options
        collection = options[:collection]
        collection = collection.call if collection.respond_to?(:call)
        Array(collection).map { |v| [v.to_s.humanize, v] }
      end

      def self.searchable?
        true
      end
    end
  end
end
