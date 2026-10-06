# frozen_string_literal: true

module RecordingStudioInternationalization
  Locale = Data.define(:code, :name, :direction, :fallbacks) do
    def rtl? = direction == :rtl
  end

  class Manifest
    include Enumerable

    ENGLISH = :en
    ATTRIBUTES = %i[name direction fallbacks].freeze
    DIRECTIONS = %i[ltr rtl].freeze
    RTL_LANGUAGES = %w[ar ckb dv fa he ps sd ug ur yi].freeze

    class << self
      # Accepts an Array of codes or a Hash of code => metadata, as written in Ruby, YAML, or config.x.
      def parse(raw)
        locales = {}
        entries(raw).each do |raw_code, attributes|
          code = locale_code(raw_code)
          raise ConfigurationError, "#{raw_code.inspect} repeats #{code}" if locales.key?(code)

          locales[code] = build(code, attributes)
        end
        locales[ENGLISH] ||= build(ENGLISH, nil)
        check_fallbacks(locales)
        new(locales.values)
      end

      private

      def entries(raw)
        raw.is_a?(Hash) ? raw.to_a : Array(raw).map { |code| [code, nil] }
      end

      def locale_code(raw) = Tag.code(raw) || raise(ConfigurationError, "#{raw.inspect} is not a locale code")

      def build(code, attributes)
        attributes = metadata(code, attributes)
        Locale.new(
          code:,
          name: (attributes[:name] || default_name(code)).to_s,
          direction: direction(code, attributes[:direction]),
          fallbacks: Array(attributes[:fallbacks]).map { |raw| fallback_code(code, raw) }
        )
      end

      def metadata(code, attributes)
        return {} if attributes.nil?
        raise ConfigurationError, "#{code} metadata must be a Hash" unless attributes.is_a?(Hash)

        attributes = attributes.transform_keys(&:to_sym)
        unknown = attributes.keys - ATTRIBUTES
        raise ConfigurationError, "#{code} has unknown metadata: #{unknown.join(', ')}" if unknown.any?

        attributes
      end

      def default_name(code) = code == ENGLISH ? "English" : code.to_s

      def direction(code, raw)
        direction = raw.nil? ? default_direction(code) : raw.to_s.to_sym
        return direction if DIRECTIONS.include?(direction)

        raise ConfigurationError, "#{code} direction must be ltr or rtl, not #{raw.inspect}"
      end

      def default_direction(code)
        RTL_LANGUAGES.include?(code.to_s.split("-").first) ? :rtl : :ltr
      end

      def fallback_code(code, raw)
        Tag.code(raw) || raise(ConfigurationError, "#{code} falls back to #{raw.inspect}, which is not a locale code")
      end

      def check_fallbacks(locales)
        locales.each_value do |locale|
          unknown = locale.fallbacks - locales.keys
          next if unknown.empty?

          raise ConfigurationError, "#{locale.code} falls back to #{unknown.join(', ')}, which is not available"
        end
      end
    end

    private_class_method :new

    def initialize(locales)
      @locales = locales.freeze
      @by_code = locales.to_h { |locale| [locale.code, locale] }.freeze
    end

    def each(&) = @locales.each(&)

    def [](code) = @by_code[code]

    def english = @by_code.fetch(ENGLISH)

    # Walks the value's own tag, then its parents, so "fr-CA" finds :fr. It never walks down, because
    # "pt" does not say which regional variant the reader wants.
    def match(raw)
      code = Tag.code(raw)
      return unless code

      @by_code.values_at(*Tag.lineage(code)).compact.first
    end
  end

  module Tag
    SHAPE = /\A[a-z]{2,3}(?:-[a-z0-9]{1,8})*\z/
    # RFC 5646 sizes language tags to 35 characters. A longer cookie or header value is not a locale.
    MAX_LENGTH = 35

    class << self
      # BCP 47 casing, so "pt_br", "PT-br", and :"pt-BR" are all :"pt-BR". I18n keys YAML by this exact code.
      def code(raw)
        return unless raw.is_a?(String) || raw.is_a?(Symbol)

        text = raw.to_s.strip.downcase.tr("_", "-")
        return unless text.length <= MAX_LENGTH && SHAPE.match?(text)

        language, *subtags = text.split("-")
        [language, *subtags.map { |subtag| canonical_subtag(subtag) }].join("-").to_sym
      end

      def lineage(code)
        subtags = code.to_s.split("-")
        subtags.size.downto(1).map { |size| subtags.first(size).join("-").to_sym }
      end

      private

      def canonical_subtag(subtag)
        case subtag
        when /\A[a-z]{2}\z/ then subtag.upcase
        when /\A[a-z]{4}\z/ then subtag.capitalize
        else subtag
        end
      end
    end
  end
  private_constant :Tag
end
