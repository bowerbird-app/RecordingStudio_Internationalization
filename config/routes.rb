# frozen_string_literal: true

RecordingStudioInternationalization::Engine.routes.draw do
  root "home#index"
  patch "locale", to: "locales#update", as: :locale
end
