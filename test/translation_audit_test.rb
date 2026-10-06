# frozen_string_literal: true

require "test_helper"
require "stringio"
require "yaml"

class TranslationAuditTest < Minitest::Test
  TranslationAudit = RecordingStudioInternationalization::TranslationAudit

  def setup
    @original_configuration = RecordingStudioInternationalization.instance_variable_get(:@configuration)
    RecordingStudioInternationalization.instance_variable_set(
      :@configuration,
      RecordingStudioInternationalization::Configuration.new
    )
    store(:en, {
            hello: "Hello",
            recording_studio: {
              messages: { inbox: { title: "Inbox", empty: "No messages yet" } },
              presskits: { index: { title: "Press kits" } }
            }
          })
    store(:fr, {
            hello: "Bonjour",
            recording_studio: { messages: { inbox: { title: "Boîte de réception", empty: nil } } }
          })
  end

  def teardown
    I18n.backend.reload!
    RecordingStudioInternationalization.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_missing_lists_untranslated_keys_and_counts_a_nil_leaf_as_missing
    status, out, err = run_audit(:missing, "fr")

    assert_equal 1, status
    assert_equal <<~TEXT, out
      fr.recording_studio.messages.inbox.empty
      fr.recording_studio.presskits.index.title
      fr: 2 missing
    TEXT
    assert_equal "", err
  end

  def test_missing_counts_a_parent_locale_translation_as_present
    store(:"fr-CA", { recording_studio: { presskits: { index: { title: "Dossiers de presse" } } } })

    status, out, = run_audit(:missing, "fr_ca")

    assert_equal 1, status
    assert_equal "fr-CA.recording_studio.messages.inbox.empty\nfr-CA: 1 missing\n", out
  end

  def test_missing_reports_keys_under_a_non_hash_node_as_missing
    store(:de, { recording_studio: { messages: "Nachrichten", presskits: { index: { title: "Pressemappen" } } } })

    status, out, = run_audit(:missing, "de")

    assert_equal 1, status
    assert_equal <<~TEXT, out
      de.recording_studio.messages.inbox.empty
      de.recording_studio.messages.inbox.title
      de: 2 missing
    TEXT
  end

  def test_missing_without_a_locale_audits_every_configured_locale_except_english
    RecordingStudioInternationalization.configure { |config| config.available_locales = %w[en ja fr] }
    store(:ja, {
            recording_studio: {
              messages: { inbox: { title: "受信箱", empty: "メッセージはありません" } },
              presskits: { index: { title: "プレスキット" } }
            }
          })

    assert_equal [0, "ja: 0 missing\n", ""], run_audit(:missing, "ja")

    status, out, = run_audit(:missing, nil)

    assert_equal 1, status
    assert_equal <<~TEXT, out
      ja: 0 missing
      fr.recording_studio.messages.inbox.empty
      fr.recording_studio.presskits.index.title
      fr: 2 missing
    TEXT
  end

  def test_missing_and_export_reject_a_malformed_locale
    assert_equal [2, "", "Pass a locale code such as fr, not \"../fr\".\n"], run_audit(:missing, "../fr")
    assert_equal [2, "", "Pass a locale code such as fr, not nil.\n"], run_audit(:export, nil)
  end

  def test_missing_needs_a_backend_that_lists_translations
    I18n.stub(:backend, Object.new) do
      assert_equal [2, "", "Object cannot list its translations.\n"], run_audit(:missing, "fr")
    end
  end

  def test_export_prints_only_the_gaps_as_yaml_with_english_comments
    status, out, err = run_audit(:export, "fr")

    assert_equal [0, ""], [status, err]
    assert_equal <<~YAML, out
      fr:
        recording_studio:
          messages:
            inbox:
              empty: ~ # en: "No messages yet"
          presskits:
            index:
              title: ~ # en: "Press kits"
    YAML
    assert_equal(
      { "fr" => { "recording_studio" => { "messages" => { "inbox" => { "empty" => nil } },
                                          "presskits" => { "index" => { "title" => nil } } } } },
      YAML.safe_load(out)
    )
  end

  def test_export_quotes_keys_that_yaml_would_read_as_booleans
    store(:en, { recording_studio: { languages: { no: "Norwegian", "it's": "Possessive" } } })

    _status, out, = run_audit(:export, "no")

    assert_includes out, "\n      'no': ~ # en: \"Norwegian\"\n"
    assert_equal(
      { "no" => { "recording_studio" => {
        "languages" => { "it's" => nil, "no" => nil },
        "messages" => { "inbox" => { "empty" => nil, "title" => nil } },
        "presskits" => { "index" => { "title" => nil } }
      } } },
      YAML.safe_load(out)
    )
  end

  private

  def store(locale, data)
    I18n.backend.store_translations(locale, data)
  end

  def run_audit(task, locale)
    out = StringIO.new
    err = StringIO.new
    status = TranslationAudit.public_send(task, locale, out:, err:)
    [status, out.string, err.string]
  end
end
