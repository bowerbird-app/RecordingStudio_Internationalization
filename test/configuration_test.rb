# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  ConfigurationError = RecordingStudioInternationalization::ConfigurationError

  def setup
    @configuration = RecordingStudioInternationalization::Configuration.new
  end

  def test_defaults_are_english_only_with_country_detection_off
    assert_equal(
      {
        available_locales: [:en],
        default_locale: :en,
        country_detection: false,
        country_locales: {
          "JP" => :ja, "FR" => :fr, "DE" => :de, "AT" => :de, "IT" => :it, "ES" => :es, "PT" => :pt,
          "BR" => :pt, "MX" => :es, "KR" => :ko, "NL" => :nl, "PL" => :pl, "SE" => :sv
        },
        current_user_method: :current_user,
        hooks_registered: {}
      },
      @configuration.to_h
    )
    assert_instance_of RecordingStudio::Hooks, @configuration.hooks
  end

  def test_merge_applies_yaml_shaped_values
    @configuration.merge!(
      available_locales: %w[en fr],
      default_locale: "fr",
      country_source: "CF-IPCountry",
      country_locales: { CA: "fr" },
      current_user_method: "current_member"
    )

    assert_equal %i[en fr], @configuration.available_locales.map(&:code)
    assert_equal :fr, @configuration.default_locale
    assert_equal "JP", @configuration.country_for(Struct.new(:headers).new({ "CF-IPCountry" => "JP" }))
    assert_equal :fr, @configuration.country_locales.tag_for("CA")
    assert_equal :current_member, @configuration.current_user_method
  end

  def test_merge_accepts_string_keys_and_ignores_removed_template_settings
    @configuration.merge!("available_locales" => ["ja"], "api_key" => "ignored", "timeout" => 9)

    assert_equal %i[ja en], @configuration.available_locales.map(&:code)
    refute_respond_to @configuration, :api_key
    refute_respond_to @configuration, :timeout
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_equal original, @configuration.to_h
  end

  def test_country_source_accepts_a_callable_and_nil_turns_detection_off
    request = Struct.new(:headers).new({ "X-Geo" => "jp" })

    @configuration.country_source = ->(req) { req.headers["X-Geo"].upcase }
    from_callable = @configuration.country_for(request)
    @configuration.country_source = nil

    assert_equal "JP", from_callable
    assert_nil @configuration.country_for(request)
  end

  def test_setters_reject_values_they_cannot_use
    assert_raises(ConfigurationError) { @configuration.country_source = 42 }
    assert_raises(ConfigurationError) { @configuration.country_source = " " }
    assert_raises(ConfigurationError) { @configuration.default_locale = "French" }
    assert_raises(ConfigurationError) { @configuration.current_user_method = nil }
    assert_raises(ConfigurationError) { @configuration.available_locales = { fr: { fallbacks: [:de] } } }
  end

  def test_default_locale_is_stored_canonically
    @configuration.default_locale = "pt_br"

    assert_equal :"pt-BR", @configuration.default_locale
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioInternationalization.configure

    assert_kind_of RecordingStudioInternationalization::Configuration, RecordingStudioInternationalization.configuration
  end
end
