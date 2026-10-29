# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_internationalization.gemspec
gemspec

# recording_studio is not published to RubyGems; resolve the gemspec pin from GitHub.
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v6.3.0"
# Recording Studio 6 depends on flat_pack, which is not published to RubyGems.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.329"

gem "devise"
gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "minitest-mock"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
