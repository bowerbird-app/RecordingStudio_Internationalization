# frozen_string_literal: true

module RecordingStudioInternationalization
  # Raw request text. Resolver parses every field, so any of them may be nil, malformed, or not offered.
  Signals = Data.define(:explicit, :profile, :stored, :accept_language, :country) do
    def initialize(explicit: nil, profile: nil, stored: nil, accept_language: nil, country: nil) = super
  end

  Decision = Data.define(:locale, :source) do
    def explicit? = source == :explicit
  end

  class Resolver
    # Highest precedence first. The first candidate the manifest matches wins.
    SOURCES = {
      explicit: lambda(&:explicit),
      profile: lambda(&:profile),
      stored: lambda(&:stored),
      accept_language: ->(signals) { AcceptLanguage.tags(signals.accept_language) },
      country: ->(signals) { countries.tag_for(signals.country) },
      default_locale: ->(_signals) { default_locale }
    }.freeze

    def initialize(manifest:, countries: CountryTable.parse({}), default_locale: Manifest::ENGLISH)
      @manifest = manifest
      @countries = countries
      @default_locale = default_locale
    end

    def resolve(signals)
      SOURCES.each do |source, candidates|
        Array(instance_exec(signals, &candidates)).each do |raw|
          locale = manifest.match(raw)
          return Decision.new(locale:, source:) if locale
        end
      end
      Decision.new(locale: manifest.english, source: :english)
    end

    private

    attr_reader :manifest, :countries, :default_locale
  end

  class CountryTable
    # Only countries with one dominant language. CA, BE, and CH are multilingual, and US, GB, and AU are
    # left to the default locale, so none of them guess until the host maps them.
    BUILT_IN = {
      "JP" => :ja, "FR" => :fr, "DE" => :de, "AT" => :de, "IT" => :it, "ES" => :es, "PT" => :pt,
      "BR" => :pt, "MX" => :es, "KR" => :ko, "NL" => :nl, "PL" => :pl, "SE" => :sv
    }.freeze
    COUNTRY = /\A[A-Z]{2}\z/

    # A nil value removes a built-in country.
    def self.parse(overrides)
      raise ConfigurationError, "country_locales must be a Hash" unless overrides.nil? || overrides.is_a?(Hash)

      table = (overrides || {}).each_with_object(BUILT_IN.dup) do |(raw_country, raw_language), entries|
        country = country_code(raw_country)
        if raw_language.nil?
          entries.delete(country)
        else
          entries[country] = language_tag(raw_language)
        end
      end
      new(table.freeze)
    end

    def self.country_code(raw)
      country = raw.to_s.upcase
      return country if COUNTRY.match?(country)

      raise ConfigurationError, "#{raw.inspect} is not a two-letter country code"
    end

    def self.language_tag(raw) = Tag.code(raw) || raise(ConfigurationError, "#{raw.inspect} is not a language tag")

    private_class_method :new, :country_code, :language_tag

    def initialize(table)
      @table = table
    end

    def tag_for(country) = @table[country.to_s.strip.upcase]

    def to_h = @table
  end

  module AcceptLanguage
    class << self
      def tags(header)
        return [] unless header.is_a?(String)

        header.split(",").each_with_index
              .filter_map { |entry, position| weighted_tag(entry, position) }
              .sort_by { |_tag, quality, position| [-quality, position] }
              .map(&:first)
      end

      private

      def weighted_tag(entry, position)
        tag, *parameters = entry.split(";").map(&:strip)
        quality = q_value(parameters)
        [tag, quality, position] if quality&.positive? && !tag.to_s.empty? && tag != "*"
      end

      def q_value(parameters)
        q = parameters.find { |parameter| parameter.match?(/\Aq\s*=/i) }
        q ? Float(q.split("=", 2).last.strip, exception: false) : 1.0
      end
    end
  end
  private_constant :AcceptLanguage
end
