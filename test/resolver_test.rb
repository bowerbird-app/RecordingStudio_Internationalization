# frozen_string_literal: true

require "test_helper"

class ResolverTest < Minitest::Test
  Signals = RecordingStudioInternationalization::Signals
  Manifest = RecordingStudioInternationalization::Manifest
  CountryTable = RecordingStudioInternationalization::CountryTable
  Resolver = RecordingStudioInternationalization::Resolver
  Configuration = RecordingStudioInternationalization::Configuration

  def test_no_configuration_resolves_to_english
    configuration = Configuration.new
    resolver = Resolver.new(manifest: configuration.available_locales, countries: configuration.country_locales)

    decision = resolver.resolve(Signals.new(stored: "fr", accept_language: "fr-CA,fr;q=0.9", country: "FR"))

    assert_equal %i[en default_locale], [decision.locale.code, decision.source]
  end

  def test_explicit_choice_beats_profile_cookie_and_browser
    decision = resolve(
      Signals.new(explicit: "fr", profile: "ja", stored: "en", accept_language: "de"),
      available: %i[en fr ja de]
    )

    assert_equal %i[fr explicit], [decision.locale.code, decision.source]
    assert_predicate decision, :explicit?
  end

  def test_profile_beats_cookie
    decision = resolve(Signals.new(profile: "ja", stored: "fr"), available: %i[en fr ja])

    assert_equal %i[ja profile], [decision.locale.code, decision.source]
  end

  def test_cookie_beats_accept_language
    decision = resolve(Signals.new(stored: "ja", accept_language: "fr"), available: %i[en fr ja])

    assert_equal %i[ja stored], [decision.locale.code, decision.source]
    refute_predicate decision, :explicit?
  end

  def test_browser_detection_is_skipped_when_a_cookie_is_present
    decision = resolve(Signals.new(stored: "en", accept_language: "fr,ja;q=0.9"), available: %i[en fr ja])

    assert_equal %i[en stored], [decision.locale.code, decision.source]
  end

  def test_a_cookie_for_a_removed_locale_falls_through_to_the_browser
    decision = resolve(Signals.new(stored: "de", accept_language: "fr"), available: %i[en fr])

    assert_equal %i[fr accept_language], [decision.locale.code, decision.source]
  end

  def test_regional_browser_tag_finds_its_language
    decision = resolve(Signals.new(accept_language: "fr-CA,en;q=0.8"), available: %i[en fr])

    assert_equal %i[fr accept_language], [decision.locale.code, decision.source]
  end

  def test_regional_browser_tag_does_not_select_another_language
    decision = resolve(Signals.new(accept_language: "fr-CA"), available: %i[en ja])

    assert_equal %i[en default_locale], [decision.locale.code, decision.source]
  end

  def test_accept_language_orders_by_quality_then_header_order
    assert_equal :fr, resolve(Signals.new(accept_language: "ja;q=0.5, fr;q=0.9"), available: %i[en fr ja]).locale.code
    assert_equal :ja, resolve(Signals.new(accept_language: "ja, fr"), available: %i[en fr ja]).locale.code
    assert_equal :ja, resolve(Signals.new(accept_language: "de, ja;q=0.2"), available: %i[en fr ja]).locale.code
  end

  def test_accept_language_drops_wildcards_zero_quality_and_unreadable_quality
    decision = resolve(Signals.new(accept_language: "fr;q=0, ja;q=abc, *"), available: %i[en fr ja])

    assert_equal %i[en default_locale], [decision.locale.code, decision.source]
  end

  def test_country_is_ignored_while_country_source_is_nil
    configuration = Configuration.new
    configuration.available_locales = %i[en ja]
    request = Struct.new(:headers).new({ "CF-IPCountry" => "JP" })

    decision = resolver_for(configuration).resolve(Signals.new(country: configuration.country_for(request)))

    assert_equal %i[en default_locale], [decision.locale.code, decision.source]
  end

  def test_country_source_header_feeds_the_country_signal
    configuration = Configuration.new
    configuration.available_locales = %i[en ja]
    configuration.country_source = "CF-IPCountry"
    request = Struct.new(:headers).new({ "CF-IPCountry" => "JP" })

    decision = resolver_for(configuration).resolve(Signals.new(country: configuration.country_for(request)))

    assert_equal %i[ja country], [decision.locale.code, decision.source]
  end

  def test_country_selects_a_language_only_when_it_is_available_and_nothing_better_matched
    assert_equal %i[ja country], code_and_source(Signals.new(country: "JP"), available: %i[en ja])
    assert_equal %i[en default_locale], code_and_source(Signals.new(country: "JP"), available: %i[en fr])
    assert_equal %i[en stored], code_and_source(Signals.new(stored: "en", country: "JP"), available: %i[en ja])
  end

  def test_country_loses_to_accept_language
    decision = resolve(Signals.new(accept_language: "en-US,en;q=0.9", country: "JP"), available: %i[en ja])

    assert_equal %i[en accept_language], [decision.locale.code, decision.source]
  end

  def test_canada_does_not_guess_a_language_until_the_host_maps_it
    signals = Signals.new(country: "CA")

    assert_equal %i[en default_locale], code_and_source(signals, available: %i[en fr])
    assert_equal %i[fr country], code_and_source(signals, available: %i[en fr], countries: { "CA" => "fr" })
  end

  def test_portuguese_does_not_match_brazilian_portuguese
    assert_equal %i[en default_locale], code_and_source(Signals.new(accept_language: "pt"), available: %w[en pt-BR])
    assert_equal %i[pt-BR accept_language],
                 code_and_source(Signals.new(accept_language: "pt-br"), available: %w[en pt-BR])
  end

  def test_resolver_returns_symbol_codes_from_a_configured_default
    decision = resolve(Signals.new, available: %w[en pt_BR], default_locale: :"pt-BR")

    assert_equal %i[pt-BR default_locale], [decision.locale.code, decision.source]
  end

  def test_english_is_the_last_resort_when_the_default_is_not_offered
    decision = resolve(Signals.new(explicit: "../../etc", stored: "x" * 200), available: %i[en fr], default_locale: :de)

    assert_equal %i[en english], [decision.locale.code, decision.source]
  end

  private

  def resolve(signals, available:, countries: {}, default_locale: :en)
    Resolver.new(
      manifest: Manifest.parse(available),
      countries: CountryTable.parse(countries),
      default_locale:
    ).resolve(signals)
  end

  def code_and_source(signals, **)
    decision = resolve(signals, **)
    [decision.locale.code, decision.source]
  end

  def resolver_for(configuration)
    Resolver.new(manifest: configuration.available_locales, countries: configuration.country_locales)
  end
end
