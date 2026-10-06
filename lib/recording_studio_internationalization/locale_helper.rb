# frozen_string_literal: true

module RecordingStudioInternationalization
  module LocaleHelper
    def recording_studio_language_selector(**html_options)
      locales = RecordingStudioInternationalization.configuration.available_locales
      return if locales.count < 2

      render "recording_studio_internationalization/locales/selector", locales:, html_options:
    end

    def recording_studio_locale_attributes
      locale = RecordingStudioInternationalization.configuration.available_locales[I18n.locale]
      { lang: I18n.locale.to_s, dir: locale&.rtl? ? "rtl" : "ltr" }
    end
  end
end
