# ruby -Ilib test/helper_api_test.rb — guards against helpers silently disappearing.
require "minitest/autorun"

class HelperApiTest < Minitest::Test
  PUBLIC_HELPERS = %w[
    atu_html_attributes atu_font_faces_tag atu_icon atu_badge atu_button atu_page_header atu_card
    atu_stat_grid atu_stat_card atu_delta atu_money atu_sparkline atu_distribution atu_crumbs atu_crumbs_nav
    atu_chart atu_alert atu_modal atu_modal_trigger atu_empty_state atu_filter_tabs
    atu_navigation_groups atu_navigation_pinned atu_user_menu atu_nav_item atu_field_errors
  ].freeze

  def test_every_documented_helper_is_defined
    src = File.read(File.expand_path("../app/helpers/administrate_theme_ui/components_helper.rb", __dir__))
    defined = src.scan(/^\s+def (atu_[a-z_?]+)/).flatten
    assert_empty PUBLIC_HELPERS - defined, "missing helpers"
  end

  def test_every_helper_used_in_views_is_defined
    src = File.read(File.expand_path("../app/helpers/administrate_theme_ui/components_helper.rb", __dir__))
    defined = src.scan(/^\s+def (atu_[a-z_?]+)/).flatten
    used = Dir[File.expand_path("../{app/views,lib/generators}/**/*.erb", __dir__)].flat_map { |f| File.read(f).scan(/\b(atu_[a-z_]+)\(/).flatten }.uniq
    assert_empty used - defined, "views call undefined helpers"
  end
end
