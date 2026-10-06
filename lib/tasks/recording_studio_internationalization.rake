# frozen_string_literal: true

namespace :recording_studio_internationalization do
  desc "List recording_studio.* English keys a locale lacks. Without a locale, audit every configured locale."
  task :missing, [:locale] => :environment do |_task, args|
    exit RecordingStudioInternationalization::TranslationAudit.missing(args[:locale], out: $stdout, err: $stderr)
  end

  desc "Print YAML for the recording_studio.* keys a locale lacks. Writes to stdout only."
  task :export, [:locale] => :environment do |_task, args|
    exit RecordingStudioInternationalization::TranslationAudit.export(args[:locale], out: $stdout, err: $stderr)
  end
end
