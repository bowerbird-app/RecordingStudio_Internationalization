# frozen_string_literal: true

require "recording_studio"
require "recording_studio_internationalization/version"
require "recording_studio_internationalization/manifest"
require "recording_studio_internationalization/resolver"
require "recording_studio_internationalization/preference"
require "recording_studio_internationalization/i18n_setup"
require "recording_studio_internationalization/translation_audit"
require "recording_studio_internationalization/locale_helper"
require "recording_studio_internationalization/localized"
require "recording_studio_internationalization/configuration"
require "recording_studio_internationalization/engine"

module RecordingStudioInternationalization
  # Raised while parsing configuration, so a bad value fails at boot instead of on a request.
  class ConfigurationError < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
