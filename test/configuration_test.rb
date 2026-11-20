# ruby -Ilib test/configuration_test.rb  (no Rails needed)
require "minitest/autorun"
require "administrate_theme_ui/configuration"

class ConfigurationTest < Minitest::Test
  def setup = @c = AdministrateThemeUi::Configuration.new

  def test_rejects_unknown_theme_and_mode
    assert_raises(ArgumentError) { @c.theme = :neon }
    assert_raises(ArgumentError) { @c.default_mode = :sepia }
    @c.theme = "ledger"
    assert_equal :ledger, @c.theme
  end

  def test_default_tones_normalise_input
    assert_equal :success, @c.tone_for("Approved")
    assert_equal :danger, @c.tone_for("FAILED")
    assert_equal :info, @c.tone_for("sent to partner")
    assert_equal :neutral, @c.tone_for("something_else")
    assert_equal :neutral, @c.tone_for(nil)
  end

  def test_per_page_defaults
    assert_equal [10, 20, 50, 100], @c.per_page_options
    assert_equal 20, @c.default_per_page
  end

  def test_custom_tones_win_over_defaults
    @c.status_tones = { warning: %w[approved] }
    assert_equal :warning, @c.tone_for("approved")
  end
end
