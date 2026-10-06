# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  ConfigurationError = RecordingStudioInternationalization::ConfigurationError

  def setup
    @original_configuration = RecordingStudioInternationalization.instance_variable_get(:@configuration)
    RecordingStudioInternationalization.instance_variable_set(
      :@configuration,
      RecordingStudioInternationalization::Configuration.new
    )
  end

  def teardown
    RecordingStudioInternationalization.configuration.hooks.clear!
    RecordingStudioInternationalization.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_before_and_after_initialize_initializers_run_hooks
    before_called = false
    after_called = false

    RecordingStudioInternationalization.configuration.hooks.before_initialize { |_engine| before_called = true }
    RecordingStudioInternationalization.configuration.hooks.after_initialize { |_engine| after_called = true }

    find_initializer("recording_studio_internationalization.before_initialize").block.call(Object.new)
    find_initializer("recording_studio_internationalization.after_initialize").block.call(Object.new)

    assert before_called
    assert after_called
  end

  def test_load_config_merges_config_sources_and_runs_on_configuration_hook
    hook_payload = nil
    RecordingStudioInternationalization.configuration.hooks.on_configuration { |cfg| hook_payload = cfg }

    app = fake_app(
      yaml: { available_locales: %w[en fr], country_locales: { CA: "fr" } },
      config_x: { country_source: "X-Country-Code" }
    )

    find_initializer("recording_studio_internationalization.load_config").block.call(app)

    configuration = RecordingStudioInternationalization.configuration
    assert_equal configuration, hook_payload
    assert_equal %i[en fr], configuration.available_locales.map(&:code)
    assert_equal :fr, configuration.country_locales.tag_for("CA")
    assert_equal "CA", configuration.country_for(Struct.new(:headers).new({ "X-Country-Code" => "CA" }))
  end

  def test_load_config_applies_yaml_then_config_x_over_the_configure_block
    RecordingStudioInternationalization.configure do |config|
      config.available_locales = %w[en fr ja]
      config.default_locale = :fr
      config.country_locales = { "CA" => "fr" }
    end

    app = fake_app(yaml: { default_locale: "ja", country_locales: { CA: "ja" } }, config_x: { default_locale: "en" })
    find_initializer("recording_studio_internationalization.load_config").block.call(app)

    configuration = RecordingStudioInternationalization.configuration
    assert_equal :en, configuration.default_locale
    assert_equal :ja, configuration.country_locales.tag_for("CA")
    assert_equal %i[en fr ja], configuration.available_locales.map(&:code)
  end

  def test_load_config_raises_configuration_errors_instead_of_dropping_them
    yaml_app = fake_app(yaml: { available_locales: ["français"] }, config_x: {})
    pair_app = fake_app(yaml: nil, config_x: pair_config(:country_source, 42))

    yaml_error = assert_raises(ConfigurationError) do
      find_initializer("recording_studio_internationalization.load_config").block.call(yaml_app)
    end
    assert_raises(ConfigurationError) do
      find_initializer("recording_studio_internationalization.load_config").block.call(pair_app)
    end
    assert_equal "\"français\" is not a locale code", yaml_error.message
  end

  def test_load_config_handles_errors_and_each_pair_fallback
    xcfg = Struct.new(:recording_studio_internationalization).new(pair_config(:default_locale, "fr"))
    app = Struct.new(:config) do
      def config_for(_name)
        raise "missing file"
      end
    end.new(Struct.new(:x).new(xcfg))

    find_initializer("recording_studio_internationalization.load_config").block.call(app)

    assert_equal :fr, RecordingStudioInternationalization.configuration.default_locale
  end

  def test_load_config_swallow_each_pair_errors
    bad_pair_config = Class.new do
      def each_pair
        raise "bad pair"
      end
    end.new

    app = fake_app(yaml: { available_locales: ["ja"] }, config_x: bad_pair_config)

    find_initializer("recording_studio_internationalization.load_config").block.call(app)

    assert_equal %i[ja en], RecordingStudioInternationalization.configuration.available_locales.map(&:code)
  end

  def test_load_config_is_noop_without_config_sources
    app = Struct.new(:config).new(Object.new)

    find_initializer("recording_studio_internationalization.load_config").block.call(app)

    assert_equal(
      { available_locales: [:en], default_locale: :en, country_detection: false, current_user_method: :current_user },
      RecordingStudioInternationalization.configuration.to_h.except(:country_locales, :hooks_registered)
    )
  end

  def test_load_config_ignores_non_enumerable_yaml_and_merge_errors
    yaml = Class.new do
      def each
        raise "bad yaml"
      end
    end.new

    find_initializer("recording_studio_internationalization.load_config").block.call(
      fake_app(yaml:, config_x: { default_locale: "ja" })
    )

    assert_equal :ja, RecordingStudioInternationalization.configuration.default_locale
  end

  def test_i18n_initializer_gives_rails_english_settings_for_zero_configuration
    i18n = run_i18n_initializer

    assert_equal({ available_locales: [:en], default_locale: :en, fallbacks: [:en] }, settings(i18n))
  end

  def test_i18n_initializer_unions_host_locales_and_maps_declared_fallbacks
    RecordingStudioInternationalization.configure do |config|
      config.available_locales = { en: {}, fr: {}, ca: { fallbacks: [:es] }, es: {} }
    end

    i18n = run_i18n_initializer(available_locales: ["de"])

    assert_equal(
      { available_locales: %i[de en fr ca es], default_locale: :en, fallbacks: [:en, { ca: [:es] }] },
      settings(i18n)
    )
  end

  def test_i18n_initializer_writes_the_configured_default_while_rails_is_still_english
    RecordingStudioInternationalization.configure do |config|
      config.available_locales = %w[en fr]
      config.default_locale = :fr
    end

    i18n = run_i18n_initializer(default_locale: :en)

    assert_equal({ available_locales: %i[en fr], default_locale: :fr, fallbacks: %i[fr en] }, settings(i18n))
  end

  def test_i18n_initializer_keeps_an_offered_host_default
    RecordingStudioInternationalization.configure { |config| config.available_locales = %w[en ja] }

    i18n = run_i18n_initializer(default_locale: "ja")

    assert_equal({ available_locales: %i[en ja], default_locale: :ja, fallbacks: %i[ja en] }, settings(i18n))
  end

  def test_i18n_initializer_rejects_a_host_default_that_is_not_offered
    error = assert_raises(ConfigurationError) { run_i18n_initializer(default_locale: :de) }

    assert_equal "default locale :de is not in available_locales", error.message
  end

  def test_i18n_initializer_leaves_host_fallback_choices_alone
    chosen = ActiveSupport::OrderedOptions.new
    chosen.defaults = [:fr]

    [true, false, [:fr], { ca: [:es] }, chosen].each do |fallbacks|
      assert_same fallbacks, run_i18n_initializer(fallbacks:).fallbacks
    end
    assert_nil run_i18n_initializer(fallbacks: nil).fallbacks
    assert_equal [:en], run_i18n_initializer.fallbacks
  end

  def test_apply_extension_initializers_register_active_support_on_load_callbacks
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    RecordingStudioInternationalization::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_internationalization.apply_model_extensions").block.call
      find_initializer("recording_studio_internationalization.apply_controller_extensions").block.call
    end

    assert_equal 2, to_prepare_blocks.size
  end

  def test_model_extension_initializer_skips_abstract_models
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    abstract_model = Class.new do
      def self.abstract_class?
        true
      end
    end
    concrete_model = Class.new do
      def self.abstract_class?
        false
      end
    end
    applied = []
    active_record_base = Class.new
    active_record_base.define_singleton_method(:descendants) { [abstract_model, concrete_model] }

    RecordingStudioInternationalization::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_internationalization.apply_model_extensions").block.call
    end

    with_temporary_nested_constant(:ActiveRecord, :Base, active_record_base) do
      RecordingStudioInternationalization::Engine.stub(:apply_model_extensions, ->(model) { applied << model }) do
        to_prepare_blocks.first.call
      end
    end

    assert_equal [concrete_model], applied
  end

  def test_controller_extension_initializer_applies_all_controllers
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    first_controller = Class.new
    second_controller = Class.new
    applied = []
    action_controller_base = Class.new
    action_controller_base.define_singleton_method(:descendants) { [first_controller, second_controller] }

    RecordingStudioInternationalization::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_internationalization.apply_controller_extensions").block.call
    end

    engine = RecordingStudioInternationalization::Engine
    with_temporary_nested_constant(:ActionController, :Base, action_controller_base) do
      engine.stub(:apply_controller_extensions, ->(controller) { applied << controller }) do
        to_prepare_blocks.first.call
      end
    end

    assert_equal [first_controller, second_controller], applied
  end

  def test_apply_model_extensions_adds_registered_methods_once
    model_class = Class.new do
      def self.name
        "ExampleRecord"
      end
    end

    RecordingStudioInternationalization.configuration.hooks.extend_model(:ExampleRecord) do
      def template_extension_method
        :applied
      end
    end

    RecordingStudioInternationalization::Engine.apply_model_extensions(model_class)
    RecordingStudioInternationalization::Engine.apply_model_extensions(model_class)

    instance = model_class.new
    assert_equal :applied, instance.template_extension_method
  end

  def test_apply_controller_extensions_matches_demodulized_name
    controller_class = Class.new do
      def self.name
        "Admin::DashboardController"
      end
    end

    RecordingStudioInternationalization.configuration.hooks.extend_controller(:DashboardController) do
      def template_controller_extension
        :applied
      end
    end

    RecordingStudioInternationalization::Engine.apply_controller_extensions(controller_class)

    instance = controller_class.new
    assert_equal :applied, instance.template_controller_extension
  end

  def test_apply_extensions_flattens_compacts_and_tracks_identity
    target = Class.new
    extension = proc do
      def generated_method
        :generated
      end
    end

    RecordingStudioInternationalization::Engine.send(:apply_extensions, target, [nil, [extension, extension]])

    applied = target.instance_variable_get(:@recording_studio_internationalization_applied_extensions)
    assert_equal :generated, target.new.generated_method
    assert_equal true, applied.compare_by_identity?
  end

  def test_apply_extensions_returns_without_target
    assert_nil RecordingStudioInternationalization::Engine.send(:apply_extensions, nil, [])
  end

  def test_extension_keys_for_includes_demodulized_name
    namespaced = Class.new do
      def self.name
        "Admin::ReportsController"
      end
    end

    expected_keys = [:"Admin::ReportsController"]
    expected_keys << :ReportsController

    assert_equal expected_keys, RecordingStudioInternationalization::Engine.send(:extension_keys_for, namespaced)
  end

  def test_extension_keys_for_removes_duplicate_names
    plain = Class.new do
      def self.name
        "ReportsController"
      end
    end

    assert_equal [:ReportsController], RecordingStudioInternationalization::Engine.send(:extension_keys_for, plain)
  end

  private

  def fake_app(yaml:, config_x:)
    app_config = Struct.new(:x).new(Struct.new(:recording_studio_internationalization).new(config_x))
    Struct.new(:config, :yaml) do
      def config_for(_name)
        yaml
      end
    end.new(app_config, yaml)
  end

  def pair_config(key, value)
    Class.new do
      define_method(:each_pair) { |&block| block.call(key, value) }
    end.new
  end

  def run_i18n_initializer(available_locales: nil, default_locale: nil, fallbacks: ActiveSupport::OrderedOptions.new)
    i18n = ActiveSupport::OrderedOptions.new
    i18n.available_locales = available_locales
    i18n.default_locale = default_locale
    i18n.fallbacks = fallbacks
    app = Struct.new(:config).new(Struct.new(:i18n).new(i18n))
    find_initializer("recording_studio_internationalization.i18n").block.call(app)
    i18n
  end

  def settings(i18n)
    i18n.to_h.slice(:available_locales, :default_locale, :fallbacks)
  end

  def with_temporary_nested_constant(parent_name, child_name, value)
    parent_defined = Object.const_defined?(parent_name, false)
    parent = parent_defined ? Object.const_get(parent_name) : Object.const_set(parent_name, Module.new)
    child_defined = parent.const_defined?(child_name, false)
    previous_child = parent.const_get(child_name) if child_defined

    parent.const_set(child_name, value)
    yield
  ensure
    parent.send(:remove_const, child_name) if parent.const_defined?(child_name, false)
    parent.const_set(child_name, previous_child) if child_defined
    Object.send(:remove_const, parent_name) unless parent_defined
  end

  def find_initializer(name)
    RecordingStudioInternationalization::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
