# Dummy chrome i18n findings

Switching English → French → Japanese on `/` now updates dummy chrome, not only the Inbox / Press room fixture strings.

## What was leftover English

Hard-coded copy in the dummy host, not in this gem's library:

- Home title/subtitle (`Template Demo`)
- Card titles and body copy (Language, What's working, Next steps, FlatPack usage, Install flow)
- `dummy_page_nav` chrome: Sign out, Home back label, document titles
- Docs page titles, subtitles, empty states, and table headers
- Devise sign-in labels (Login, Email, Password, Remember me, Sign In)

## What we did

Dummy-only. Views and `dummy_page_nav` wrap that copy in `t("dummy.*")`. Matching keys live in `test/dummy/config/locales/{en,fr,ja}.yml`. French and Japanese are real translations.

The existing language selector and `recording_studio_locale` cookie are unchanged. Core Recording Studio layout is not forked. The dummy Devise layout sets `lang` / `dir` from `recording_studio_locale_attributes`.

## Still English on purpose

- Workspace names (`Client Workspace`) — database content
- Key names in the Language card (`messages.inbox.title`) — identifiers
- French `messages.inbox.empty` still falls back to `No messages yet` — the dummy still omits that host translation so English fallback is visible
- Flatpack's own `Code Example` label on docs code blocks
- Code samples

## Screenshots

- `01-english-home.png` — Template Demo, Sign out, card titles in English
- `02-french-home.png` — Démo du modèle, Déconnexion, Langue
- `03-japanese-home.png` — テンプレートデモ, ログアウト, 言語
- `04-japanese-install.png` — インストール / ログアウト
