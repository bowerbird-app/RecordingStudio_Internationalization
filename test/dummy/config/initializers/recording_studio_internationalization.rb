# frozen_string_literal: true

RecordingStudioInternationalization.configure do |config|
  config.available_locales = {
    en: { name: "English" },
    fr: { name: "Français" },
    ja: { name: "日本語" }
  }
  config.country_source = "CF-IPCountry"
  config.country_locales = { "CA" => "fr" }
end
