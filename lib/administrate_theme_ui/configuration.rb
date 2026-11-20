module AdministrateThemeUi
  class Configuration
    THEMES = %i[graphite ledger].freeze
    MODES = %i[light dark system].freeze

    # Default status → tone map used by `atu_badge` / Field::StatusBadge.
    # Tones: success, warning, danger, info, neutral, accent.
    DEFAULT_STATUS_TONES = {
      success: %w[active approved completed success succeeded paid done enabled verified disbursed closed_paid],
      warning: %w[pending waiting processing in_progress review on_hold draft partial],
      danger:  %w[failed rejected error cancelled canceled expired blocked declined disabled overdue],
      info:    %w[new submitted sent queued scheduled sent_to_partner],
      neutral: %w[inactive closed archived unknown]
    }.freeze

    attr_accessor :app_name, :logo_path, :default_mode, :allow_user_theme_switch,
                  :navigation_groups, :status_tones, :currency_unit, :delimiter, :separator, :number_locale,
                  :navigation_resources, :navigation_pinned
    attr_reader :theme

    def initialize
      @app_name = "Admin"
      @logo_path = nil
      @theme = :graphite
      @currency_unit = "Rp"
      @delimiter = "."
      @separator = ","
      @number_locale = "id-ID" # chart axes/tooltips via Intl.NumberFormat
      # Proc evaluated in the view (instance_exec) returning the sidebar resources,
      # e.g. -> { @sidebar_menus } for a role-filtered list. nil = every routed resource.
      @navigation_resources = nil
      # Proc evaluated in the view returning [[label, path], ...] pinned above the groups.
      @navigation_pinned = nil
      @default_mode = :system
      @allow_user_theme_switch = true
      # { "Finance" => %i[transactions repayments], ... } — ungrouped resources land in "Resources".
      @navigation_groups = {}
      @status_tones = {}
    end

    def theme=(value)
      value = value.to_sym
      raise ArgumentError, "Unknown theme #{value.inspect}. Available: #{THEMES.join(', ')}" unless THEMES.include?(value)

      @theme = value
    end

    def default_mode=(value)
      value = value.to_sym
      raise ArgumentError, "Unknown mode #{value.inspect}. Available: #{MODES.join(', ')}" unless MODES.include?(value)

      @default_mode = value
    end

    def tone_for(status)
      key = status.to_s.downcase.strip.tr(" -", "__")
      custom = status_tones.find { |_tone, values| Array(values).map(&:to_s).include?(key) }
      return custom.first.to_sym if custom

      DEFAULT_STATUS_TONES.find { |_tone, values| values.include?(key) }&.first || :neutral
    end
  end
end
