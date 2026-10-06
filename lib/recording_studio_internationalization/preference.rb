# frozen_string_literal: true

module RecordingStudioInternationalization
  module Preference
    COOKIE = "recording_studio_locale"
    PROFILE_KEY = "locale"

    class << self
      def stored(cookies) = cookies[COOKIE]

      def profile(user)
        return unless user && profile_integration?

        ::RecordingStudioUser.profile_for(user)&.additional_profile_attributes&.[](PROFILE_KEY)
      end

      # Profile first, so a signed-in user keeps the choice even if the cookie write never happens.
      def remember!(locale, cookies:, user:)
        value = locale.code.to_s
        write_profile(user, value) if user && profile_integration?
        return if cookies[COOKIE] == value

        cookies.permanent[COOKIE] = { value:, httponly: true, same_site: :lax, path: "/" }
      end

      private

      # Checked per call, because Bundler.require can load the users gem after this one. Without the
      # :locale allowlist this gem could read a profile value it can never overwrite, and that stale
      # value would beat every later choice.
      def profile_integration?
        defined?(::RecordingStudioUser) &&
          ::RecordingStudioUser.respond_to?(:profile_for) &&
          ::RecordingStudioUser.respond_to?(:record_profile!) &&
          ::RecordingStudioUser.config.additional_profile_attributes.include?(:locale)
      end

      # record_profile! replaces first_name, last_name, time_zone, and the whole extras hash, and it turns
      # an absent time_zone into "UTC", so every current value goes back in. Creating profiles is the
      # users gem's job.
      def write_profile(user, value)
        profile = ::RecordingStudioUser.profile_for(user)
        return if profile.nil? || profile.additional_profile_attributes[PROFILE_KEY] == value

        ::RecordingStudioUser.record_profile!(
          user,
          actor: user,
          first_name: profile.first_name,
          last_name: profile.last_name,
          time_zone: profile.time_zone,
          additional_profile_attributes: profile.additional_profile_attributes.merge(PROFILE_KEY => value)
        )
      end
    end
  end
  private_constant :Preference
end
