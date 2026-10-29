# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.9] - 2026-10-29

Removed the unused `config.hooks.extend_model` / `extend_controller` API. The install generator no longer writes FlatPack Tailwind sources. Dummy docs label recordings with Recording Studio's helpers, and the dummy pins move to current sibling tags.

### Removed

- `config.hooks.extend_model` and `config.hooks.extend_controller` are no longer applied. `before_initialize`, `on_configuration`, and `after_initialize` are unchanged.

### Changed

- The install generator adds only this gem's Tailwind `@source` lines. For FlatPack's sources, run `bin/rails generate flat_pack:install`.
- Dummy docs `/docs/methods` shows `RecordingStudio.recordable_name` and `RecordingStudio.recordable_type_label`. `/docs/recordings_tree` uses those helpers and lists only the current root.
- Dummy Gemfile pins: Recording Studio `v6.3.0`, Accessible `v0.23.1`, Trashable `v0.12.0`, Root Switchable `v0.11.2`, Metrics `v0.7.0`, Cache `v0.6.0`, FlatPack `v0.1.329`, view_component `4.19.0`, Users `v0.26.5` (`require: false`), Admin `v2.5.1` (`require: false`), Attachable `v0.22.0` (`require: false`).
- The dummy shell uses `recording_studio_layout` and FlatPack cards use `background`, `border`, and `shadow`. Recording Studio 6 dropped `UsesDefaultLayout`, and FlatPack 0.1.329 rejects `Card` `style:`.
- Coverage reports are no longer tracked.

### Upgrade notes

- No migration.
- Delete any `config.hooks.extend_model` or `config.hooks.extend_controller` blocks registered on this gem. They no longer run. Use Recording Studio for model and controller extension.
- Hosts that relied on this generator for FlatPack Tailwind sources should run `bin/rails generate flat_pack:install`.
- The published gemspec is unchanged. The pin list above is the dummy app and its lockfile.

## [0.1.8] - 2026-10-27

Widened the `recording_studio` runtime constraint so hosts and sibling gems on 6.x, including 6.1.0, can resolve this gem.

### Changed

- `recording_studio` dependency is now `>= 4.2, < 7` (was `~> 4.2`). 4.x and 5.x still resolve; 6.x is allowed.

### Upgrade notes

- No migration and no configuration change. Hosts already on Recording Studio 4.x or 5.x are unchanged. Hosts on 6.x can now bundle this gem.

## [0.1.2] - 2026-10-07

The dummy app now translates its own chrome. Switching English, French, or Japanese updates titles, card headings, Sign out, and the sign-in form, not only the sample gem strings.

### Changed

- Dummy views wrap host copy in `dummy.*` keys for `en`, `fr`, and `ja`.

### Upgrade notes

- No migration and no configuration change. Host apps are unchanged.

## [0.1.1] - 2026-10-06

The gem's English file now contains only the language selector. Sample inbox and press kit strings were fixtures for the dummy app, and they belong with the gems that own those screens.

### Changed

- Removed `recording_studio.messages` and `recording_studio.presskits` from the packaged English locale.

### Upgrade notes

- No migration and no configuration change.
- If a host was showing "Inbox", "No messages yet", or "Press kits" from this gem, move those strings into the gem that owns the screen, or into the host's locale file.

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
