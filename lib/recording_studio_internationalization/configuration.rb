# frozen_string_literal: true

module RecordingStudioInternationalization
  class Configuration
    attr_reader :available_locales, :default_locale, :country_source, :country_locales, :current_user_method, :hooks

    def initialize
      @available_locales = Manifest.parse(nil)
      @default_locale = Manifest::ENGLISH
      @country_source = nil
      @country_locales = CountryTable.parse(nil)
      @current_user_method = :current_user
      @hooks = RecordingStudio::Hooks.new
    end

    def available_locales=(value)
      @available_locales = Manifest.parse(value)
    end

    def default_locale=(value)
      @default_locale = Tag.code(value) ||
                        raise(ConfigurationError, "default_locale #{value.inspect} is not a locale code")
    end

    # nil turns country detection off. A String names a request header. A callable receives the request.
    def country_source=(value)
      unless value.nil? || value.is_a?(String) || value.respond_to?(:call)
        raise ConfigurationError, "country_source must be nil, a header name, or a callable"
      end

      @country_source = value.is_a?(String) ? header_reader(value) : value
    end

    def country_locales=(value)
      @country_locales = CountryTable.parse(value)
    end

    def current_user_method=(value)
      unless value.is_a?(String) || value.is_a?(Symbol)
        raise ConfigurationError, "current_user_method must be a method name, not #{value.inspect}"
      end

      @current_user_method = value.to_sym
    end

    def country_for(request) = country_source&.call(request)

    def to_h
      {
        available_locales: available_locales.map(&:code),
        default_locale:,
        country_detection: !country_source.nil?,
        country_locales: country_locales.to_h,
        current_user_method:,
        hooks_registered: hooks.registered_counts
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end

    # A host source that fails to load is skipped, so the initializer values stand. A value this gem
    # rejects still raises, so a typo stops boot.
    def merge_source!
      merge!(yield)
    rescue ConfigurationError
      raise
    rescue StandardError
      nil
    end

    private

    def header_reader(name)
      raise ConfigurationError, "country_source header name is blank" if name.strip.empty?

      ->(request) { request.headers[name] }
    end
  end
end
