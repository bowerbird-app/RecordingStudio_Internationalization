# frozen_string_literal: true

module RecordingStudioInternationalization
  module Localized
    extend ActiveSupport::Concern

    UNLOCALIZED_NAMESPACES = %w[ActiveStorage:: ActionMailbox:: Rails::].freeze

    included do
      around_action :use_recording_studio_locale, unless: :recording_studio_unlocalized?
      etag { I18n.locale }
      helper LocaleHelper
    end

    private

    def use_recording_studio_locale(&)
      I18n.with_locale(recording_studio_locale_decision.locale.code, &)
    end

    def recording_studio_locale_decision
      @recording_studio_locale_decision ||= recording_studio_resolver.resolve(recording_studio_signals)
    end

    def recording_studio_explicit_locale = nil

    def recording_studio_signals
      Signals.new(
        explicit: recording_studio_explicit_locale,
        profile: Preference.profile(recording_studio_user),
        stored: Preference.stored(cookies),
        accept_language: request.headers["Accept-Language"],
        country: RecordingStudioInternationalization.configuration.country_for(request)
      )
    end

    def recording_studio_resolver
      configuration = RecordingStudioInternationalization.configuration
      Resolver.new(
        manifest: configuration.available_locales,
        countries: configuration.country_locales,
        default_locale: I18n.default_locale
      )
    end

    # current_user, not Current.actor, because hosts often set Current.actor in a later before_action.
    def recording_studio_user
      name = RecordingStudioInternationalization.configuration.current_user_method
      send(name) if respond_to?(name, true)
    end

    def recording_studio_unlocalized?
      self.class.name.to_s.start_with?(*UNLOCALIZED_NAMESPACES)
    end
  end
  private_constant :Localized
end
