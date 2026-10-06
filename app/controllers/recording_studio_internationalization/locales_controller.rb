# frozen_string_literal: true

module RecordingStudioInternationalization
  class LocalesController < ApplicationController
    def update
      decision = recording_studio_locale_decision
      Preference.remember!(decision.locale, cookies:, user: recording_studio_user) if decision.explicit?
      redirect_to url_from(params[:return_to]) || "/", status: :see_other, allow_other_host: false
    end

    private

    def recording_studio_explicit_locale = params[:locale]
  end
end
