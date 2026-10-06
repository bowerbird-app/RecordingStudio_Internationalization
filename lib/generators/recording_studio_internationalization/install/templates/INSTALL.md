RecordingStudioInternationalization install complete.

Next steps:

1. Set `available_locales` in config/initializers/recording_studio_internationalization.rb. English is always available.
2. If you use environment-specific settings, create config/recording_studio_internationalization.yml. YAML values override the initializer.
3. If your app's signed-in user method is not `current_user`, set `current_user_method`.
4. Render `<%= recording_studio_language_selector %>` in a layout or page. It submits to the engine mount path.
5. Add `recording_studio_locale_attributes` to your layout's `<html>` tag so `lang` and `dir` follow the locale.
6. Run `bin/rails recording_studio_internationalization:missing` to list gem strings your locale files do not translate yet.
7. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
