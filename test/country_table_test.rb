# frozen_string_literal: true

require "test_helper"

class CountryTableTest < Minitest::Test
  CountryTable = RecordingStudioInternationalization::CountryTable
  ConfigurationError = RecordingStudioInternationalization::ConfigurationError

  def test_built_in_table_maps_single_language_countries_to_plain_language_tags
    table = CountryTable.parse(nil)

    assert_equal :ja, table.tag_for("JP")
    assert_equal :fr, table.tag_for(" fr ")
    assert_equal :pt, table.tag_for("BR")
    assert_equal :de, table.tag_for("AT")
  end

  def test_built_in_table_leaves_multilingual_and_english_speaking_countries_unmapped
    table = CountryTable.parse({})

    assert_equal(
      { "JP" => :ja, "US" => nil, "GB" => nil, "AU" => nil, "CA" => nil, "BE" => nil, "CH" => nil },
      %w[JP US GB AU CA BE CH].to_h { |country| [country, table.tag_for(country)] }
    )
    assert_nil table.tag_for(nil)
    assert_nil table.tag_for("ZZ")
  end

  def test_host_overrides_win_and_nil_removes_a_built_in
    table = CountryTable.parse("CA" => "fr", ch: "de_ch", "JP" => nil)

    assert_equal :fr, table.tag_for("CA")
    assert_equal :"de-CH", table.tag_for("CH")
    assert_nil table.tag_for("JP")
  end

  def test_parse_rejects_malformed_countries_and_languages
    country = assert_raises(ConfigurationError) { CountryTable.parse("CAN" => "fr") }
    language = assert_raises(ConfigurationError) { CountryTable.parse("CA" => "French") }
    shape = assert_raises(ConfigurationError) { CountryTable.parse(%w[CA fr]) }

    assert_equal "\"CAN\" is not a two-letter country code", country.message
    assert_equal "\"French\" is not a language tag", language.message
    assert_equal "country_locales must be a Hash", shape.message
  end
end
