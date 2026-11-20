module AdministrateThemeUi
  # UI components available in every Administrate view (and in any view that
  # includes this helper). All output is escaped unless passed as a block.
  module ComponentsHelper
    TONES = %i[success warning danger info neutral accent].freeze

    # <html> attributes: configured theme + default mode. The pre-paint script
    # (see layout) overrides both from the user's localStorage choice.
    def atu_html_attributes
      cfg = AdministrateThemeUi.config
      {
        lang: I18n.locale,
        "data-theme": cfg.theme,
        "data-mode-default": cfg.default_mode,
        "data-theme-switch": cfg.allow_user_theme_switch,
        "data-atu-locale": cfg.number_locale
      }
    end

    FONTS = [
      ["ATU Plex Sans", 400, "ibm-plex-sans-400"], ["ATU Plex Sans", 500, "ibm-plex-sans-500"], ["ATU Plex Sans", 600, "ibm-plex-sans-600"],
      ["ATU Plex Mono", 400, "ibm-plex-mono-400"], ["ATU Plex Mono", 500, "ibm-plex-mono-500"],
      ["ATU Serif", 400, "source-serif-4-400"], ["ATU Serif", 600, "source-serif-4-600"]
    ].freeze

    # Registers the vendored fonts with the FontFace API. Not @font-face in CSS:
    # Administrate 1.0's anchor-positioning polyfill re-emits stylesheets as blob:
    # URLs, so root-relative url() in @font-face fails to load.
    def atu_font_faces_tag
      fonts = FONTS.map { |family, weight, file| [family, weight, asset_path("administrate_theme_ui/#{file}.woff2")] }
      javascript_tag(nonce: true) do
        <<~JS.html_safe
          (function () {
            if (!window.FontFace || !document.fonts) return;
            #{fonts.to_json}.forEach(function (f) {
              var face = new FontFace(f[0], "url(" + new URL(f[2], location.href).href + ") format('woff2')", { weight: String(f[1]), display: "swap" });
              document.fonts.add(face);
            });
          })();
        JS
      end
    end

    def atu_icon(name, size: 18, **attrs)
      tag.svg(width: size, height: size, "aria-hidden": "true", class: ["atu-icon", attrs.delete(:class)], **attrs) do
        tag.use(href: "#atu-i-#{name}")
      end
    end

    def atu_badge(text, tone: nil, dot: true) # dot is hidden by the Ledger theme
      tone = (tone || AdministrateThemeUi.config.tone_for(text)).to_sym
      tone = :neutral unless TONES.include?(tone)
      tag.span(class: "atu-badge atu-badge--#{tone}") do
        safe_join([(tag.span(class: "atu-badge__dot") if dot), text.to_s.humanize].compact)
      end
    end

    def atu_button(label, url = nil, variant: :primary, size: nil, icon: nil, **opts)
      classes = ["atu-btn", "atu-btn--#{variant.to_s.dasherize}", ("atu-btn--#{size}" if size), opts.delete(:class)]
      content = safe_join([(atu_icon(icon, size: 15) if icon), label].compact)
      url ? link_to(content, url, class: classes, **opts) : tag.button(content, type: opts.delete(:type) || "button", class: classes, **opts)
    end

    def atu_page_header(title, subtitle: nil, &actions)
      tag.header(class: "atu-page-header") do
        safe_join([
          tag.div(class: "atu-page-header__text") do
            safe_join([tag.h1(title, class: "atu-page-header__title", id: "page-title"),
                       (tag.p(subtitle, class: "atu-page-header__subtitle") if subtitle)].compact)
          end,
          (tag.div(capture(&actions), class: "atu-page-header__actions") if actions)
        ].compact)
      end
    end

    def atu_card(title: nil, subtitle: nil, actions: nil, flush: false, **opts, &block)
      tag.section(class: ["atu-card", ("atu-card--flush" if flush), opts.delete(:class)], **opts) do
        head = if title || actions
                 tag.header(class: "atu-card__header") do
                   safe_join([
                     tag.div { safe_join([(tag.h2(title, class: "atu-card__title") if title), (tag.p(subtitle, class: "atu-card__subtitle") if subtitle)].compact) },
                     (tag.div(actions, class: "atu-card__actions") if actions)
                   ].compact)
                 end
               end
        safe_join([head, tag.div(capture(&block), class: "atu-card__body")].compact)
      end
    end

    def atu_stat_grid(&block)
      tag.div(capture(&block), class: "atu-stat-grid")
    end

    # One KPI cell. Put several inside atu_stat_grid; they render as a single
    # divided strip, not floating cards.
    #   value: string or atu_money(...)  delta: % change (numeric)  spark: [numbers]
    def atu_stat_card(label:, value:, hint: nil, link: nil, link_text: nil, delta: nil, delta_label: nil,
                      spark: nil, icon: nil, tone: nil)
      tag.div(class: ["atu-stat", ("atu-stat--#{tone}" if tone)]) do
        safe_join([
          tag.div(class: "atu-stat__top") do
            safe_join([tag.div(class: "atu-stat__label") { safe_join([(atu_icon(icon, size: 14) if icon), label].compact) },
                       (atu_sparkline(spark, width: 72, height: 22, tone: tone) if spark.present?)].compact)
          end,
          tag.div(value, class: "atu-stat__value"),
          tag.div(class: "atu-stat__meta") do
            safe_join([
              (atu_delta(delta) unless delta.nil?),
              (tag.span(delta_label || hint, class: "atu-stat__hint") if delta_label || hint),
              (link_to(safe_join([link_text || "View", atu_icon("arrow-right", size: 13)]), link, class: "atu-stat__link") if link)
            ].compact)
          end
        ])
      end
    end

    def atu_delta(delta)
      up = delta.to_f >= 0
      tag.span("#{up ? '▲' : '▼'} #{delta.to_f.abs.round(1)}%", class: "atu-delta atu-delta--#{up ? 'up' : 'down'}",
                                                              "aria-label": "#{up ? 'Up' : 'Down'} #{delta.to_f.abs.round(1)} percent")
    end

    # Money with a de-emphasised currency unit: "Rp 11.000.000.000".
    def atu_money(amount, unit: AdministrateThemeUi.config.currency_unit, precision: 0)
      return tag.span("—", class: "atu-muted") if amount.nil?

      cfg = AdministrateThemeUi.config
      number = number_with_precision(amount, precision: precision, delimiter: cfg.delimiter, separator: cfg.separator)
      tag.span(class: "atu-money") { safe_join([tag.span(unit, class: "atu-money__unit"), number], " ") }
    end

    # Tiny inline SVG trend line, rendered server-side (no JS).
    def atu_sparkline(values, width: 88, height: 28, tone: nil)
      nums = Array(values).map(&:to_f)
      return if nums.size < 2

      min, max = nums.minmax
      span = (max - min).nonzero? || 1
      pts = nums.each_with_index.map do |v, i|
        [(i * (width - 2) / (nums.size - 1).to_f + 1).round(1), (height - 2 - ((v - min) / span * (height - 4))).round(1)]
      end
      line = pts.map { |x, y| "#{x},#{y}" }.join(" ")
      area = "1,#{height} #{line} #{width - 1},#{height}"
      tag.svg(class: ["atu-spark", ("atu-spark--#{tone}" if tone)], width: width, height: height, viewBox: "0 0 #{width} #{height}",
              "aria-hidden": "true", preserveAspectRatio: "none") do
        safe_join([tag.polygon(points: area, class: "atu-spark__area"), tag.polyline(points: line, class: "atu-spark__line")])
      end
    end

    # Proportional breakdown as one stacked bar + legend rows. Status keys get
    # their tone colour automatically. items: { "approved" => 12, ... }
    def atu_distribution(items, status: true)
      total = items.values.sum.to_f
      return atu_empty_state(title: "No data") if total.zero?

      seen = Hash.new(0)
      rows = items.sort_by { |_k, v| -v }.each_with_index.map do |(key, count), i|
        color =
          if status
            # Statuses sharing a tone get progressively lighter shades so they stay distinguishable.
            tone = AdministrateThemeUi.config.tone_for(key)
            mix = [100, 62, 38][seen[tone]] || 25
            seen[tone] += 1
            "color-mix(in srgb, var(--atu-#{tone}-solid) #{mix}%, var(--atu-surface))"
          else
            "var(--atu-chart-#{(i % 8) + 1})"
          end
        { label: key.to_s.humanize, count: count, pct: (count / total * 100), color: color }
      end
      tag.div(class: "atu-dist") do
        safe_join([
          tag.div(class: "atu-dist__bar", role: "img", "aria-label": rows.map { |r| "#{r[:label]} #{r[:pct].round}%" }.join(", ")) do
            safe_join(rows.map { |r| tag.span(style: "width: #{r[:pct].round(2)}%; background: #{r[:color]}") })
          end,
          tag.ul(class: "atu-dist__list") do
            safe_join(rows.map do |r|
              tag.li do
                safe_join([tag.span(class: "atu-dist__key", style: "background: #{r[:color]}"), tag.span(r[:label], class: "atu-dist__label"),
                           tag.span(number_with_delimiter(r[:count], delimiter: AdministrateThemeUi.config.delimiter), class: "atu-dist__count"),
                           tag.span("#{r[:pct].round(1)}%", class: "atu-dist__pct")])
              end
            end)
          end
        ])
      end
    end

    # Breadcrumbs for the topbar: atu_crumbs(["Loans", admin_loans_path], "Loan #12").
    # Pages that set none get "<app name> / <page title>" automatically.
    def atu_crumbs(*items)
      content_for(:atu_breadcrumbs) { atu_crumbs_nav(*items) }
    end

    def atu_crumbs_nav(*items)
      tag.nav(class: "atu-crumbs", "aria-label": "Breadcrumb") do
        tag.ol do
          safe_join(items.each_with_index.map do |(label, url), i|
            last = i == items.size - 1
            tag.li(last || url.nil? ? tag.span(label, "aria-current": (last ? "page" : nil)) : link_to(label, url))
          end)
        end
      end
    end

    # type: :line, :bar, :doughnut, :pie, :area. datasets: [{ label:, data: [], type: optional }]
    # Colours come from the active theme; charts re-render on theme/mode change.
    def atu_chart(type:, labels:, datasets:, height: 300, money: false, options: {})
      unless @atu_chart_js_loaded
        @atu_chart_js_loaded = true
        content_for(:javascript) { javascript_include_tag("administrate_theme_ui/chart.umd", defer: true) }
      end
      config = { type: type, labels: labels, datasets: datasets, money: money, options: options }
      tag.div(class: "atu-chart", style: "height: #{height.to_i}px") do
        tag.canvas(data: { atu_chart: config.to_json }, role: "img", "aria-label": datasets.map { |d| d[:label] }.compact.join(", "))
      end
    end

    def atu_alert(message = nil, tone: :info, title: nil, dismissible: false, &block)
      icon = { success: "check-circle", warning: "alert", danger: "x-circle", info: "info" }.fetch(tone.to_sym, "info")
      tag.div(class: "atu-alert atu-alert--#{tone}", role: tone.to_sym == :danger ? "alert" : "status") do
        safe_join([
          atu_icon(icon, size: 20, class: "atu-alert__icon"),
          tag.div(class: "atu-alert__content") do
            safe_join([(tag.strong(title, class: "atu-alert__title") if title), tag.div(block ? capture(&block) : message)].compact)
          end,
          (tag.button(atu_icon("x", size: 16), type: "button", class: "atu-alert__close", "aria-label": "Dismiss", data: { atu_dismiss: "" }) if dismissible)
        ].compact)
      end
    end

    # Native <dialog> (Esc, focus trap, inert page for free). Sizes: :sm 400, :md 560, :lg 720, :xl 960.
    # Header title + close (top-right); body scrolls; footer is right-aligned — put Cancel first,
    # the primary action last. static: true disables backdrop-click dismissal (use for forms).
    def atu_modal(id:, title:, description: nil, size: :md, footer: nil, static: false, &block)
      tag.dialog(id: id, class: "atu-modal atu-modal--#{size}", "aria-labelledby": "#{id}-title",
                 data: { atu_static: (static ? "" : nil) }) do
        tag.div(class: "atu-modal__panel") do
          safe_join([
            tag.header(class: "atu-modal__header") do
              safe_join([
                tag.div(class: "atu-modal__heading") do
                  safe_join([tag.h1(title, id: "#{id}-title", class: "atu-modal__title"),
                             (tag.p(description, class: "atu-modal__desc") if description)].compact)
                end,
                tag.button(atu_icon("x", size: 16), type: "button", class: "atu-iconbtn atu-modal__close", "aria-label": "Close", data: { atu_modal_close: "" })
              ])
            end,
            tag.div(capture(&block), class: "atu-modal__body"),
            (tag.footer(footer, class: "atu-modal__footer") if footer)
          ].compact)
        end
      end
    end

    def atu_modal_trigger(label, id, variant: :secondary, **opts)
      atu_button(label, nil, variant: variant, data: { atu_modal_open: id }, **opts)
    end

    def atu_empty_state(title:, description: nil, icon: "inbox", &action)
      tag.div(class: "atu-empty") do
        safe_join([
          tag.div(atu_icon(icon, size: 28), class: "atu-empty__icon"),
          tag.p(title, class: "atu-empty__title"),
          (tag.p(description, class: "atu-empty__desc") if description),
          (tag.div(capture(&action), class: "atu-empty__action") if action)
        ].compact)
      end
    end

    # Sidebar items grouped by config.navigation_groups. Resources come from
    # config.navigation_resources (e.g. a role-filtered list) or, by default, every
    # routed resource in the namespace. Dashboard-less custom pages are listed too.
    def atu_navigation_groups(namespace)
      cfg = AdministrateThemeUi.config
      groups = cfg.navigation_groups.transform_values { |v| Array(v).map(&:to_s) }
      grouped = groups.keys.index_with { [] }
      other = []
      resources = cfg.navigation_resources ? instance_exec(&cfg.navigation_resources) : Administrate::Namespace.new(namespace).resources_with_index_route
      Array(resources).each do |resource|
        item = atu_nav_item(resource)
        next unless item

        group = groups.find { |_g, names| names.include?(resource.to_s.split("/").last) }&.first
        group ? grouped[group] << item : other << item
      end
      grouped["Resources"] = other if other.any?
      grouped.reject { |_g, list| list.empty? }
    end

    # Links pinned above the groups (config.navigation_pinned), e.g. a dashboard.
    def atu_navigation_pinned
      pinned = AdministrateThemeUi.config.navigation_pinned
      return [] unless pinned

      Array(instance_exec(&pinned)).map { |label, path| { label: label, path: path, active: current_page?(path) } }
    end

    # Topbar user menu (render it from an app's `_user_menu` partial):
    #   atu_user_menu(name: current_admin.name, detail: current_admin.role, links: [["Sign out", sign_out_path]])
    # A link entry may carry link_to options: ["Sign out", path, { method: :delete }].
    def atu_user_menu(name:, detail: nil, links: [])
      initials = name.to_s.split.map { |w| w[0] }.first(2).join.upcase
      tag.details(class: "atu-user", data: { atu_menu: "" }) do
        safe_join([
          tag.summary(class: "atu-user__trigger", "aria-label": "Account menu for #{name}") do
            safe_join([tag.span(initials, class: "atu-user__avatar", "aria-hidden": "true"),
                       tag.span(class: "atu-user__text") { safe_join([tag.span(name, class: "atu-user__name"), (tag.span(detail, class: "atu-user__detail") if detail)].compact) },
                       atu_icon("chevron-down", size: 14, class: "atu-user__chevron")])
          end,
          tag.div(class: "atu-user__menu", role: "menu") do
            safe_join([
              tag.div(class: "atu-user__head") { safe_join([tag.strong(name), (tag.span(detail) if detail)].compact) },
              *links.map { |label, path, opts| link_to(label, path, { class: "atu-user__item", role: "menuitem" }.merge(opts || {})) }
            ])
          end
        ])
      end
    end

    def atu_nav_item(resource)
      label =
        begin
          return unless accessible_action?(model_from_resource(resource), :index)

          display_resource_name(resource)
        rescue NameError
          resource.to_s.split("/").last.titleize
        end
      { label: label, path: resource_index_route(resource), active: nav_link_state(resource) == :active }
    end

    # Per-attribute errors for inline form validation.
    def atu_field_errors(resource, attribute)
      keys = [attribute.to_sym, attribute.to_s.delete_suffix("_id").to_sym].uniq
      keys.flat_map { |k| resource.errors.full_messages_for(k) }.uniq
    end
  end
end
