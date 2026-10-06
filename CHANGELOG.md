# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-06

First release of the Recording Studio internationalization gem. The repository started from the Recording Studio gem template and is now this engine.

### Added

- Host configuration for available locales, the default locale, an optional country header, and the method that returns the signed-in user.
- Per-request locale resolution. An explicit choice beats a saved user preference, a cookie, `Accept-Language`, an optional country guess, the host default, and English.
- English fallback through Rails I18n when the host has not configured fallbacks itself.
- A language selector helper and `lang` / `dir` attributes. The host decides where they appear.
- Optional profile persistence when `recording_studio_user` is installed and `:locale` is allowlisted. The gem does not depend on that gem.
- `recording_studio_internationalization:missing` and `recording_studio_internationalization:export` for the `recording_studio` translation namespace.

### Upgrade notes

- Add `gem "recording_studio_internationalization"` and run `bin/rails generate recording_studio_internationalization:install`.
- No migration. An application that adds nothing else runs in English.
- To offer another language, list it in `available_locales` and add a host locale file. Recording Studio gems keep shipping English only.
- To remember a signed-in user's language, install Recording Studio Users and add `:locale` to `additional_profile_attributes`.
