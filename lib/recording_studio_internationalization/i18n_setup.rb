# frozen_string_literal: true

module RecordingStudioInternationalization
  module I18nSetup
    class << self
      def assignments(manifest, default_locale:, host_default:, host_available:, fallbacks:)
        default = effective_default(manifest, default_locale, host_default)
        settings = {
          default_locale: default,
          available_locales: Array(host_available).map(&:to_sym) | manifest.map(&:code)
        }
        settings[:fallbacks] = fallbacks_for(manifest, default) if unset?(fallbacks)
        settings
      end

      private

      # Rails' own default is :en, so only another value is the host's choice.
      def effective_default(manifest, default_locale, host_default)
        host_default = host_default&.to_sym
        default = [nil, Manifest::ENGLISH].include?(host_default) ? default_locale : host_default
        return default if manifest[default]

        raise ConfigurationError, "default locale #{default.inspect} is not in available_locales"
      end

      # Rails starts config.i18n.fallbacks as an empty OrderedOptions. Every other value is a host decision.
      def unset?(fallbacks)
        fallbacks.is_a?(ActiveSupport::OrderedOptions) && fallbacks.empty?
      end

      def fallbacks_for(manifest, default)
        declared = manifest.filter_map { |locale| [locale.code, locale.fallbacks] if locale.fallbacks.any? }.to_h
        [default, Manifest::ENGLISH].uniq + (declared.empty? ? [] : [declared])
      end
    end
  end
  private_constant :I18nSetup
end
