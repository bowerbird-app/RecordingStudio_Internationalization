# frozen_string_literal: true

# Loaded with the engine locales, ahead of this app's config/locales, so a host
# file can still override a string that another gem shipped.
fixtures = Rails::Paths::Root.new(Rails.root)
fixtures.add "config/gem_locale_fixtures", glob: "**/*.{rb,yml}"
Rails.application.config.i18n.railties_load_path.unshift(fixtures["config/gem_locale_fixtures"])
