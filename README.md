# Recording Studio internationalization

Recording Studio gems define the vocabulary. Host applications define the languages. English is the universal fallback.

This gem is a thin layer on Rails I18n. A Recording Studio gem ships translation keys and English text. The host application chooses which languages it offers and supplies the translations for those languages. The gem that owns a screen does not need to know that French, Japanese, or any other language exists.

Interface text and user-created content are separate. This gem translates buttons, labels, and other static interface copy. It does not translate press kit titles, biographies, or anything stored in the database. It also does not add locale prefixes to URLs.

## Install

Add the gem and mount the engine.

```ruby
gem "recording_studio_internationalization", github: "bowerbird-app/RecordingStudio_Internationalization"
```

```bash
bin/rails generate recording_studio_internationalization:install
```

The generator mounts the engine and writes `config/initializers/recording_studio_internationalization.rb`. An application that does nothing else runs in English.

There is no database migration.

## Configure the languages

```ruby
RecordingStudioInternationalization.configure do |config|
  config.available_locales = {
    en: { name: "English" },
    fr: { name: "Français" },
    ja: { name: "日本語" },
    ar: { name: "العربية" }
  }
  config.default_locale = :en
end
```

`available_locales` can also be a plain list, `%i[en fr ja]`. English is always included. A locale is available even before you have translated it, so a missing translation can fall back to English instead of raising `I18n::InvalidLocale`.

Optional metadata on each locale is a human name, `direction` (`ltr` or `rtl`), and extra `fallbacks`. Arabic defaults to `rtl`. A regional code such as `pt_br` is stored as `:"pt-BR"`.

You can also set the same keys in `config/recording_studio_internationalization.yml` or `config.x.recording_studio_internationalization`. Later sources replace earlier ones, one key at a time.

1. Defaults on the configuration object.
2. The `configure` block in `config/initializers`.
3. The YAML file for the current environment.
4. `config.x.recording_studio_internationalization`.

`config.i18n.default_locale` still wins when the host has set it to something other than `:en`. That value must be one of the available locales.

## Translate interface text

A Recording Studio gem wraps static interface copy in a key under `recording_studio.<gem>.<section>.<key>` and ships the English string.

```erb
<%= t("recording_studio.presskits.actions.create") %>
```

```yaml
en:
  recording_studio:
    presskits:
      actions:
        create: "Create press kit"
```

Put that YAML in the gem that owns the screen. Rails loads it with that engine. This internationalization gem ships English only for its language selector. It does not list the host's languages, and it does not ship French, Japanese, German, or another gem's copy.

The host adds a language by dropping a locale file in its own `config/locales`. Host files load after engine files, so they override gem strings, including English.

```yaml
fr:
  recording_studio:
    presskits:
      actions:
        create: "Créer un dossier de presse"
```

```yaml
en:
  recording_studio:
    presskits:
      labels:
        singular: "Media kit"
```

Lookup order for a key is the host's translation for the active locale, then any gem translation for that locale, then English, then Rails' normal missing-translation behavior. A new gem key that nobody has translated into French shows the English text.

Older Recording Studio gems sometimes use a top-level key such as `recording_studio_presskits`. This gem does not move those keys. New strings should use the nested `recording_studio` namespace so the owning gem is visible in the key.

## How a request picks a locale

The first match that the host actually offers wins.

1. The locale submitted by the language selector on this request.
2. The signed-in user's saved locale, when that integration is available.
3. The `recording_studio_locale` cookie from an earlier explicit choice.
4. The browser `Accept-Language` header. `fr-CA` can resolve to `fr` when French is offered and Canadian French is not.
5. A country guess, only when the host turns it on.
6. The configured default locale.
7. English.

An explicit choice is stored and is not replaced by browser or country detection on a later request. A detected locale is never stored. Choosing English on purpose is an explicit choice, so a later `Accept-Language: fr` does not switch the interface back.

The engine wraps each request in `I18n.with_locale`. It does not assign `I18n.locale` in a `before_action`, because that value would leak onto the next request on the same thread.

## Language selector

Render the helper where the host wants it. The gem does not add a navigation bar or change a layout.

```erb
<html <%= tag.attributes(recording_studio_locale_attributes) %>>
  <%= recording_studio_language_selector %>
</html>
```

The control lists only the host's locales and uses each locale's human name. Submitting it stores a permanent cookie and redirects back to the current page. The selector renders nothing when English is the only locale.

The dummy app under `test/dummy` is a host. It wraps its own titles, navigation, and sign-in copy in `dummy.*` keys and ships English, French, and Japanese for those strings. Other Recording Studio gems keep shipping English only.

`recording_studio_locale_attributes` returns `lang` and `dir` for the current locale.

## Browser language

Browser detection is on unless the visitor already has a cookie or a saved user locale. The header is matched only against the host's available locales. A regional tag walks up to its language. `pt` does not select `pt-BR`, because the shorter tag does not say which regional variant the reader wants.

## Country

Country is a weak signal. Canada, Switzerland, and Australia do not imply one language. Detection is off until the host sets `country_source` to a header name or a callable. The gem does not look up IP addresses.

```ruby
config.country_source = "CF-IPCountry"
config.country_locales = { "CA" => "fr" }
```

A small built-in map covers countries with one dominant language, such as `JP` to `ja`, `FR` to `fr`, and `DE` to `de`. It does not guess for `CA`, `BE`, `CH`, `US`, `GB`, or `AU`. Set a value to `nil` to remove a built-in entry. The guess is used only when no better signal matched, and only when that language is one of the host's locales.

## Signed-in users

This gem does not depend on `recording_studio_user`. Anonymous visitors and applications that use another sign-in system still get the cookie.

When `RecordingStudioUser` is installed, a saved preference lives in the profile's `additional_profile_attributes` under `"locale"`. The host has to allow that key or the value is dropped.

```ruby
RecordingStudioUser.configure do |config|
  config.additional_profile_attributes |= [:locale]
end
```

A signed-in visitor who picks French gets the cookie and, when the allowlist includes `:locale`, a profile update. The write copies the existing name, time zone, and other extras, because `record_profile!` replaces the whole profile. A second submit of the same locale does not write again. If the user has no profile yet, the cookie is still set and no profile is created.

The reader calls `current_user` by default. Set `current_user_method` when the host uses another method. The gem does not read `Current.actor`, because many hosts assign that later in the request.

Without the users gem, or without `:locale` on the allowlist, only the cookie is used.

## Find missing translations

These tasks read the translations Rails has already loaded. They look only at the `recording_studio` namespace. They do not change files, and a missing translation is not a runtime error.

```bash
bin/rails recording_studio_internationalization:missing[fr]
bin/rails recording_studio_internationalization:export[fr]
```

`missing` prints each untranslated key and a count. The exit status is 0 when nothing is missing, 1 when keys are missing, and 2 when the locale argument is not a locale code. With no locale argument it checks every configured locale except English.

`export` prints a YAML skeleton of the gaps to stdout. Each missing key is `~`, with the English text in a comment. Redirect that output yourself if you want a file. Loading an unfilled skeleton does not replace English, because an empty string would.

## For authors of other Recording Studio gems

Replace hard-coded interface strings with `t("recording_studio.<gem>.<section>.<key>")` and ship the English YAML. Do not declare the host's languages, do not add a locale switcher, and do not require translations other than English.

Leave database content and locale-prefixed routes alone. Those are separate problems.
