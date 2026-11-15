# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 7.0 or newer, below 8 (`>= 7.0, < 8` in the gemspec; root and dummy GitHub tag `v7.0.0`)
- Accessible dummy tag `v0.43.1`, Trashable dummy tag `v0.16.1` (`require: false`; required by Accessible), Root Switchable dummy tag `v0.11.2`, Metrics dummy tag `v0.7.0`, and Cache dummy tag `v0.6.0`
- FlatPack dummy tag `v0.1.329` and `view_component` `4.24.0` (resolved from FlatPack, not a Gemfile pin)
- Users dummy tag `v0.26.5` (`require: false`), Admin dummy tag `v2.5.1` (`require: false`, so the bundle does not pull Logs), and Attachable dummy tag `v0.22.0` (`require: false`)
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
