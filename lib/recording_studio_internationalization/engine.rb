# frozen_string_literal: true

module RecordingStudioInternationalization
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioInternationalization

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, extensions_for(:model, extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, extensions_for(:controller, extension_keys_for(target)))
      end

      private

      def extensions_for(kind, names)
        hooks = RecordingStudioInternationalization.configuration.hooks
        Array(names).flat_map do |name|
          if kind == :model
            hooks.model_extensions_for(name)
          else
            hooks.controller_extensions_for(name)
          end
        end
      end

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_internationalization_applied_extensions) ||
                  identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_internationalization_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end
    end

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

    initializer "recording_studio_internationalization.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioInternationalization::Engine.apply_model_extensions(model)
        end
      end
    end

    initializer "recording_studio_internationalization.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioInternationalization::Engine.apply_controller_extensions(controller)
        end
      end
    end

    initializer "recording_studio_internationalization.localized" do
      ActiveSupport.on_load(:action_controller_base) { include Localized }
    end
  end
end
