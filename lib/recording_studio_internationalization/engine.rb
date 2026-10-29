# frozen_string_literal: true

module RecordingStudioInternationalization
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioInternationalization

    initializer "recording_studio_internationalization.before_initialize",
                before: "recording_studio_internationalization.load_config" do |_app|
      RecordingStudioInternationalization.configuration.hooks.run(:before_initialize, self)
    end

    # Host config/initializers files have already run, so YAML and then config.x override the configure block.
    initializer "recording_studio_internationalization.load_config" do |app|
      configuration = RecordingStudioInternationalization.configuration
      if app.respond_to?(:config_for)
        configuration.merge_source! { app.config_for(:recording_studio_internationalization) }
      end

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_internationalization)
        xcfg = app.config.x.recording_studio_internationalization
        if xcfg.respond_to?(:to_h)
          configuration.merge!(xcfg.to_h)
        else
          configuration.merge_source! { {}.tap { |hash| xcfg.each_pair { |k, v| hash[k] = v } } }
        end
      end

      configuration.hooks.run(:on_configuration, configuration)
    end

    # Writes app.config.i18n before Rails' initialize_i18n applies it, so Rails still owns load paths,
    # the backend, and I18n::Backend::Fallbacks.
    initializer "recording_studio_internationalization.i18n",
                after: "recording_studio_internationalization.load_config",
                before: "recording_studio_internationalization.after_initialize" do |app|
      i18n = app.config.i18n
      configuration = RecordingStudioInternationalization.configuration
      I18nSetup.assignments(
        configuration.available_locales,
        default_locale: configuration.default_locale,
        host_default: i18n.default_locale || I18n.default_locale,
        host_available: i18n.available_locales || (I18n.available_locales if I18n.available_locales_initialized?),
        fallbacks: i18n.fallbacks
      ).each { |setting, value| i18n[setting] = value }
    end

    initializer "recording_studio_internationalization.after_initialize",
                after: "recording_studio_internationalization.load_config" do |_app|
      RecordingStudioInternationalization.configuration.hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_internationalization.localized" do
      ActiveSupport.on_load(:action_controller_base) { include Localized }
    end
  end
end
