# frozen_string_literal: true

require "rails/generators"

module RecordingStudioInternationalization
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs RecordingStudioInternationalization engine into your application"

      class_option(
        :mount_path,
        type: :string,
        default: "/recording_studio_internationalization",
        desc: "Route prefix used when mounting the engine"
      )

      def mount_engine
        route %(mount RecordingStudioInternationalization::Engine, at: "#{options[:mount_path]}")
      end

      def copy_initializer
        template "recording_studio_internationalization_initializer.rb",
                 "config/initializers/recording_studio_internationalization.rb"
      end

      def add_yaml_config
        return unless yes?(
          "Would you like to add `config/recording_studio_internationalization.yml` " \
          "for environment-specific settings? [y/N]"
        )

        template "recording_studio_internationalization.yml", "config/recording_studio_internationalization.yml"
      end

      def add_tailwind_source
        tailwind_css_path = Rails.root.join("app/assets/tailwind/application.css")
        return show_missing_tailwind_notice unless File.exist?(tailwind_css_path)

        tailwind_content = File.read(tailwind_css_path)
        missing_lines = missing_tailwind_source_lines(tailwind_content)

        if missing_lines.empty?
          say "Tailwind already configured to include RecordingStudioInternationalization and FlatPack sources.", :green
          return
        end

        if tailwind_content.include?('@import "tailwindcss"')
          inject_tailwind_sources(tailwind_css_path, missing_lines)
          return
        end

        show_manual_tailwind_notice(missing_lines)
      end

      def show_readme
        readme "INSTALL.md" if behavior == :invoke
      end

      private

      def show_missing_tailwind_notice
        say "Tailwind CSS not detected. Skipping Tailwind configuration.", :yellow
        say "If you use Tailwind, add these lines to your Tailwind CSS config:", :yellow
        tailwind_source_lines.each do |line|
          say "  #{line}", :yellow
        end
      end

      def missing_tailwind_source_lines(tailwind_content)
        tailwind_source_lines.reject { |line| tailwind_content.include?(line) }
      end

      def inject_tailwind_sources(tailwind_css_path, missing_lines)
        inject_into_file tailwind_css_path, after: "@import \"tailwindcss\";\n" do
          "#{formatted_tailwind_source_block(missing_lines)}\n"
        end
        say "Added RecordingStudioInternationalization and FlatPack sources to Tailwind CSS configuration.", :green
        say "Run 'bin/rails tailwindcss:build' to rebuild your CSS.", :green
      end

      def formatted_tailwind_source_block(missing_lines)
        [
          "\n/* Include RecordingStudioInternationalization engine views for Tailwind CSS */",
          missing_lines.first(2),
          "\n/* Include FlatPack component sources for Tailwind CSS */",
          missing_lines.drop(2)
        ].flatten.reject(&:empty?).join("\n")
      end

      def show_manual_tailwind_notice(missing_lines)
        say "Could not find @import \"tailwindcss\" in your Tailwind config.", :yellow
        say "Please manually add these lines to your Tailwind CSS config:", :yellow
        missing_lines.each do |line|
          say "  #{line}", :yellow
        end
      end

      def tailwind_source_lines
        bundled_gems = "../../../../../../usr/local/bundle/ruby/**/bundler/gems"
        [
          '@source "../../vendor/bundle/**/recording_studio_internationalization/app/views/**/*.erb";',
          "@source \"#{bundled_gems}/recording_studio_internationalization-*/app/views/**/*.erb\";",
          '@source "../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}";',
          "@source \"#{bundled_gems}/flatpack-*/app/components/**/*.{rb,erb}\";"
        ]
      end
    end
  end
end
