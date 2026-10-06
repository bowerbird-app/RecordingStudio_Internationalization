# frozen_string_literal: true

module RecordingStudioInternationalization
  module TranslationAudit
    ROOT = :recording_studio
    PLAIN_KEY = /\A[A-Za-z_][\w-]*\z/
    YAML_BOOLEAN_OR_NULL = /\A(?:y|n|yes|no|on|off|true|false|null)\z/i

    Gap = Data.define(:path, :english) do
      def key = path.join(".")
    end

    class << self
      # Exit status 0 when nothing is missing, 1 when anything is, 2 for a bad argument or backend.
      def missing(raw_locale, out:, err:)
        codes = raw_locale.nil? ? audited_codes : [Tag.code(raw_locale)]
        return usage(err, raw_locale) if codes.include?(nil)

        translations = loaded_translations
        return backend_error(err) unless translations

        total = codes.sum { |code| report(out, code, gaps(translations, code)) }
        total.zero? ? 0 : 1
      end

      def export(raw_locale, out:, err:)
        code = Tag.code(raw_locale)
        return usage(err, raw_locale) unless code

        translations = loaded_translations
        return backend_error(err) unless translations

        out.puts export_yaml(code, gaps(translations, code))
        0
      end

      private

      # Tag parents count as translated, because I18n falls back to them before English. A nil leaf counts
      # as missing, so loading an unfilled export cannot block English fallback.
      def gaps(translations, code)
        chain = Tag.lineage(code)
        english = translations.fetch(:en, {})[ROOT]
        leaves(english, [ROOT]).filter_map do |path, text|
          next unless chain.all? { |locale| lookup(translations.fetch(locale, nil), path).nil? }

          Gap.new(path:, english: text)
        end.sort_by(&:key)
      end

      def audited_codes
        RecordingStudioInternationalization.configuration.available_locales.map(&:code) - [Manifest::ENGLISH]
      end

      def loaded_translations
        I18n.backend.translations(do_init: true) if I18n.backend.respond_to?(:translations)
      end

      def report(out, code, gaps)
        gaps.each { |gap| out.puts "#{code}.#{gap.key}" }
        out.puts "#{code}: #{gaps.size} missing"
        gaps.size
      end

      def leaves(node, path)
        return [] unless node.is_a?(Hash)

        node.flat_map do |key, value|
          value.is_a?(Hash) ? leaves(value, [*path, key]) : [[[*path, key], value]]
        end
      end

      def lookup(tree, path)
        path.reduce(tree) { |node, key| node[key] if node.is_a?(Hash) }
      end

      def export_yaml(code, gaps)
        tree = gaps.each_with_object({}) do |gap, root|
          *parents, leaf = gap.path
          parents.reduce(root) { |node, segment| node[segment] ||= {} }[leaf] = gap.english
        end
        yaml_lines(code => tree).join("\n")
      end

      def yaml_lines(node, depth = 0)
        node.flat_map do |segment, value|
          line = "#{'  ' * depth}#{yaml_key(segment)}:"
          value.is_a?(Hash) ? [line, *yaml_lines(value, depth + 1)] : ["#{line} ~ # en: #{value.inspect}"]
        end
      end

      # YAML 1.1 reads a bare no, on, or yes as a boolean, which would turn Norwegian's "no" into false.
      def yaml_key(segment)
        segment = segment.to_s
        return segment if PLAIN_KEY.match?(segment) && !YAML_BOOLEAN_OR_NULL.match?(segment)

        "'#{segment.gsub("'", "''")}'"
      end

      def usage(err, raw_locale)
        err.puts "Pass a locale code such as fr, not #{raw_locale.inspect}."
        2
      end

      def backend_error(err)
        err.puts "#{I18n.backend.class} cannot list its translations."
        2
      end
    end
  end
end
