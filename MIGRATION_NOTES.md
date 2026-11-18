# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 7.0 or newer, below 8 (`>= 7.0, < 8` in the gemspec; root and dummy GitHub tag `v7.7.1`)
- Accessible dummy tag `v0.54.0`, Trashable dummy tag `v1.2.0` (`require: false`; required by Accessible), Root Switchable dummy tag `v0.16.0`, Metrics dummy tag `v0.9.1`, and Cache dummy tag `v0.7.0`
- FlatPack dummy tag `v0.1.378` and `view_component` `4.24.0` (resolved from FlatPack, not a Gemfile pin). FlatPack requires `tailwind_merge` `>= 1.5.2`, so the lockfiles resolve `tailwind_merge` 1.5.6. The API gem adds `redis` 5.4.1.
- Users dummy tag `v0.36.0` (`require: false`), Admin dummy tag `v2.19.0` (`require: false`), Attachable dummy tag `v0.32.1` (`require: false`)
- Logs `v0.8.1`, API `v1.15.0`, Moveable `v6.0.1`, and Icons `v0.4.1` (`require: false`). Admin, Users, and Attachable need them, and they are not on RubyGems. The dummy keeps `config/recording_studio_api.yml` because the API gem is in the bundle.
- Public RubyGems and GitHub access for dependency installation

## Verification

Install both bundles and run the complete gem and dummy app test path:

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy app from its directory for browser verification:

```bash
cd test/dummy
bin/dev
```

Use the [FlatPack repository](https://github.com/bowerbird-app/flatpack) and the live FlatPack demo linked from the top-level README for current component documentation.
