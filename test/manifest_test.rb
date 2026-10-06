# frozen_string_literal: true

require "test_helper"

class ManifestTest < Minitest::Test
  Manifest = RecordingStudioInternationalization::Manifest
  Locale = RecordingStudioInternationalization::Locale
  ConfigurationError = RecordingStudioInternationalization::ConfigurationError

  def test_parse_canonicalizes_codes_and_appends_english
    manifest = Manifest.parse(%w[pt_br FR zh-hant-tw])

    assert_equal %i[pt-BR fr zh-Hant-TW en], manifest.map(&:code)
  end

  def test_parse_reads_hash_metadata_with_string_keys_as_yaml_gives_them
    manifest = Manifest.parse(
      "en" => nil,
      "fr" => { "name" => "Français" },
      "ar" => { "name" => "العربية" },
      "ca" => { "name" => "Català", "fallbacks" => ["es"], "direction" => "ltr" },
      "es" => { "name" => "Español" }
    )

    assert_equal(
      [
        Locale.new(code: :en, name: "English", direction: :ltr, fallbacks: []),
        Locale.new(code: :fr, name: "Français", direction: :ltr, fallbacks: []),
        Locale.new(code: :ar, name: "العربية", direction: :rtl, fallbacks: []),
        Locale.new(code: :ca, name: "Català", direction: :ltr, fallbacks: [:es]),
        Locale.new(code: :es, name: "Español", direction: :ltr, fallbacks: [])
      ],
      manifest.to_a
    )
  end

  def test_parse_of_nothing_is_english_only
    assert_equal [Locale.new(code: :en, name: "English", direction: :ltr, fallbacks: [])], Manifest.parse(nil).to_a
  end

  def test_parse_rejects_two_spellings_of_one_code
    error = assert_raises(ConfigurationError) { Manifest.parse(["pt-BR", :pt_br]) }

    assert_equal ":pt_br repeats pt-BR", error.message
  end

  def test_parse_rejects_a_value_that_is_not_a_locale_code
    error = assert_raises(ConfigurationError) { Manifest.parse(%w[fr français]) }

    assert_equal "\"français\" is not a locale code", error.message
  end

  def test_metadata_cannot_add_a_locale_through_fallbacks
    error = assert_raises(ConfigurationError) { Manifest.parse(ca: { fallbacks: [:es] }) }

    assert_equal "ca falls back to es, which is not available", error.message
  end

  def test_parse_rejects_unknown_metadata_and_bad_direction
    unknown = assert_raises(ConfigurationError) { Manifest.parse(fr: { label: "Français" }) }
    direction = assert_raises(ConfigurationError) { Manifest.parse(fr: { direction: :down }) }
    shape = assert_raises(ConfigurationError) { Manifest.parse(fr: "Français") }

    assert_equal "fr has unknown metadata: label", unknown.message
    assert_equal "fr direction must be ltr or rtl, not :down", direction.message
    assert_equal "fr metadata must be a Hash", shape.message
  end

  def test_match_walks_up_to_parents_and_never_down
    manifest = Manifest.parse(%w[en fr pt-BR])

    assert_equal :fr, manifest.match("fr-CA").code
    assert_equal :"pt-BR", manifest.match("PT_br").code
    assert_equal :"pt-BR", manifest.match("pt-BR-x-private").code
    assert_nil manifest.match("pt")
  end

  def test_match_returns_nil_for_untrusted_junk
    manifest = Manifest.parse(%w[en fr])

    assert_nil manifest.match(nil)
    assert_nil manifest.match("")
    assert_nil manifest.match("../../etc/passwd")
    assert_nil manifest.match("fr-#{'a' * 40}")
    assert_nil manifest.match(["fr"])
  end

  def test_exact_lookup_and_english
    manifest = Manifest.parse(%w[fr ar])

    assert_equal :ar, manifest[:ar].code
    assert_nil manifest["ar"]
    assert_equal Locale.new(code: :en, name: "English", direction: :ltr, fallbacks: []), manifest.english
  end
end
