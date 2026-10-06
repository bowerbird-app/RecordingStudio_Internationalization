# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "open3"
require "yaml"

class InternationalizationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  LOCALE_PATH = "/recording_studio_internationalization/locale"
  PASSWORD = "Password123!"

  FakeProfile = Struct.new(:first_name, :last_name, :time_zone, :additional_profile_attributes)

  setup do
    @user = User.find_or_create_by!(email: "i18n-test@example.com") do |record|
      record.password = PASSWORD
      record.password_confirmation = PASSWORD
    end
    sign_in @user
  end

  test "a host with an empty configure block serves English and renders no selector" do
    with_configuration(RecordingStudioInternationalization::Configuration.new) do
      get "/", headers: { "Accept-Language" => "fr" }
    end

    assert_response :success
    assert_includes response.body, "<code>messages.inbox.title</code>: Inbox"
    assert_select "form[action='#{LOCALE_PATH}']", count: 0
  end

  test "host French YAML translates gem strings and a missing French key falls back to English" do
    get "/", headers: { "Accept-Language" => "fr-CA,fr;q=0.9,en;q=0.5" }

    assert_response :success
    assert_includes response.body, "<code>messages.inbox.title</code>: Boîte de réception"
    assert_includes response.body, "<code>messages.inbox.empty</code>: No messages yet"
    assert_includes response.body, "<code>presskits.index.title</code>: Salle de presse"
    refute_match(/translation missing/i, response.body)
    assert_select "form[action='#{LOCALE_PATH}'] select[name='locale'] option[selected]", text: "Français"
    assert_select "form[action='#{LOCALE_PATH}'] input[name='return_to'][value='/']", count: 1
  end

  test "host English YAML overrides one gem string and both gem namespaces keep their keys" do
    get "/"

    assert_includes response.body, "<code>presskits.index.title</code>: Press room"
    refute_includes response.body, "Press kits"
    assert_equal "Press room", I18n.t("recording_studio.presskits.index.title", locale: :en)
    assert_equal({ title: "Inbox", empty: "No messages yet" }, I18n.t("recording_studio.messages.inbox", locale: :en))
  end

  test "without the users gem a PATCH stores a cookie that beats Accept-Language on the next request" do
    refute defined?(RecordingStudioUser)

    patch LOCALE_PATH, params: { locale: "ja", return_to: "/docs/install" }

    assert_response :see_other
    assert_redirected_to "/docs/install"
    attributes = locale_cookie_attributes
    expires = attributes.find { |attribute| attribute.start_with?("expires=") }
    assert_equal %w[httponly path=/ recording_studio_locale=ja samesite=lax], (attributes - [expires]).sort
    assert_operator Time.httpdate(expires.delete_prefix("expires=")), :>, 19.years.from_now

    get "/", headers: { "Accept-Language" => "fr" }

    assert_includes response.body, "<code>messages.inbox.title</code>: 受信箱"

    patch LOCALE_PATH, params: { locale: "ja" }

    assert_redirected_to "/"
    assert_nil locale_cookie_attributes
  end

  test "an anonymous visitor can switch and an off-site return_to falls back to the root" do
    sign_out :user

    patch LOCALE_PATH, params: { locale: "fr", return_to: "https://evil.example/phish" }
    assert_redirected_to "/"
    assert_equal "recording_studio_locale=fr", locale_cookie_attributes.first

    patch LOCALE_PATH, params: { locale: "fr", return_to: "//evil.example" }
    assert_redirected_to "/"

    patch LOCALE_PATH, params: { locale: "fr", return_to: "/users/sign_in?next=1" }
    assert_redirected_to "/users/sign_in?next=1"
  end

  test "a locale the host does not offer changes nothing" do
    patch LOCALE_PATH, params: { locale: "de" }

    assert_redirected_to "/"
    assert_nil locale_cookie_attributes
  end

  test "switching adds no locale-prefixed routes" do
    engine_paths = RecordingStudioInternationalization::Engine.routes.routes.map { |route| route.path.spec.to_s }
    host_paths = Rails.application.routes.routes.map { |route| route.path.spec.to_s }

    assert_equal ["/", "/locale(.:format)"], engine_paths.sort
    assert_empty host_paths.grep(/:locale/)

    get "/fr/"

    assert_response :not_found
  end

  test "YAML and config.x overwrite values from the configure block" do
    assert_equal :ja, RecordingStudioInternationalization.configuration.country_locales.tag_for("CA")

    get "/", headers: { "X-Country-Code" => "CA" }
    assert_includes response.body, "<code>messages.inbox.title</code>: 受信箱"

    get "/", headers: { "CF-IPCountry" => "CA" }
    assert_includes response.body, "<code>messages.inbox.title</code>: Inbox"
  end

  test "a saved profile locale beats Accept-Language and a switch rewrites every profile field" do
    profiles = { @user.id => FakeProfile.new("Ada", "Lovelace", "London", { "locale" => "ja", "pronouns" => "she" }) }
    writes = with_users_gem(allowlist: %i[pronouns locale], profiles:) do |recorded|
      get "/", headers: { "Accept-Language" => "fr" }
      assert_includes response.body, "<code>messages.inbox.title</code>: 受信箱"

      patch LOCALE_PATH, params: { locale: "fr" }
      patch LOCALE_PATH, params: { locale: "fr" }
      recorded
    end

    assert_equal(
      [{ actor: @user, first_name: "Ada", last_name: "Lovelace", time_zone: "London",
         additional_profile_attributes: { "locale" => "fr", "pronouns" => "she" } }],
      writes
    )
    assert_equal FakeProfile.new("Ada", "Lovelace", "London", { "locale" => "fr", "pronouns" => "she" }),
                 profiles[@user.id]
  end

  test "a switch never creates a profile and still sets the cookie" do
    profiles = {}
    writes = with_users_gem(allowlist: %i[locale], profiles:) do |recorded|
      patch LOCALE_PATH, params: { locale: "fr" }
      recorded
    end

    assert_equal [[], {}], [writes, profiles]
    assert_equal "recording_studio_locale=fr", locale_cookie_attributes.first
  end

  test "without the locale allowlist the profile is neither read nor written" do
    profiles = { @user.id => FakeProfile.new("Ada", "Lovelace", "London", { "locale" => "ja" }) }
    writes = with_users_gem(allowlist: %i[pronouns], profiles:) do |recorded|
      get "/", headers: { "Accept-Language" => "fr" }
      assert_includes response.body, "<code>messages.inbox.title</code>: Boîte de réception"

      patch LOCALE_PATH, params: { locale: "en" }
      recorded
    end

    assert_equal [], writes
    assert_equal "recording_studio_locale=en", locale_cookie_attributes.first
  end

  test "the missing task lists a key French lacks and nothing outside the gem namespace" do
    out, err, status = run_rails("recording_studio_internationalization:missing[fr]")

    assert_equal ["fr.recording_studio.messages.inbox.empty\nfr: 1 missing\n", 1], [out, status.exitstatus], err
  end

  test "the missing task exits cleanly for a complete locale" do
    out, err, status = run_rails("recording_studio_internationalization:missing[ja]")

    assert_equal ["ja: 0 missing\n", 0], [out, status.exitstatus], err
  end

  test "the export task prints YAML for the gaps and writes no file" do
    files_before = Dir.glob(Rails.root.join("config/**/*").to_s)

    out, err, status = run_rails("recording_studio_internationalization:export[fr]")

    assert_equal 0, status.exitstatus, err
    assert_equal <<~YAML, out
      fr:
        recording_studio:
          messages:
            inbox:
              empty: ~ # en: "No messages yet"
    YAML
    assert_equal({ "fr" => { "recording_studio" => { "messages" => { "inbox" => { "empty" => nil } } } } },
                 YAML.safe_load(out))
    assert_equal files_before, Dir.glob(Rails.root.join("config/**/*").to_s)
  end

  private

  def with_configuration(configuration)
    original = RecordingStudioInternationalization.configuration
    RecordingStudioInternationalization.instance_variable_set(:@configuration, configuration)
    yield
  ensure
    RecordingStudioInternationalization.instance_variable_set(:@configuration, original)
  end

  # Mirrors the users gem: record_profile! replaces every field, creates a missing profile, keeps only
  # allowlisted extras, and turns an absent time_zone into "UTC".
  def with_users_gem(allowlist:, profiles:)
    writes = []
    config = Struct.new(:additional_profile_attributes).new(allowlist)
    users = Module.new
    users.define_singleton_method(:config) { config }
    users.define_singleton_method(:profile_for) { |user| profiles[user.id] }
    users.define_singleton_method(:record_profile!) do |user, actor: nil, **attributes|
      extras = attributes.fetch(:additional_profile_attributes, {}).slice(*allowlist.map(&:to_s))
      time_zone = attributes.key?(:time_zone) ? attributes[:time_zone] : "UTC"
      profiles[user.id] = FakeProfile.new(attributes[:first_name], attributes[:last_name], time_zone, extras)
      writes << { actor:, **attributes }
    end
    Object.const_set(:RecordingStudioUser, users)
    yield writes
  ensure
    Object.send(:remove_const, :RecordingStudioUser) if Object.const_defined?(:RecordingStudioUser, false)
  end

  def locale_cookie_attributes
    header = Array(response.headers["set-cookie"]).join("\n")
    line = header.lines.map(&:chomp).find { |cookie| cookie.start_with?("recording_studio_locale=") }
    line&.split("; ")
  end

  def run_rails(task)
    Open3.capture3({ "RAILS_ENV" => "test" }, "bin/rails", task, chdir: Rails.root.to_s)
  end
end
