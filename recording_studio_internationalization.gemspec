# frozen_string_literal: true

require_relative "lib/recording_studio_internationalization/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_internationalization"
  spec.version     = RecordingStudioInternationalization::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/recording_studio_internationalization"
  spec.summary     = "Per-request locale selection and English fallback for Recording Studio apps"
  spec.description = "Recording Studio gems ship English strings under recording_studio.<gem>.*. " \
                     "The host lists its languages. This engine picks a locale per request, " \
                     "persists an explicit choice, and lets Rails I18n fall back to English."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/recording_studio_internationalization"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/recording_studio_internationalization/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].reject do |path|
      path == ".cursor" || path.start_with?(".cursor/")
    end
  end

  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 4.2"
end
