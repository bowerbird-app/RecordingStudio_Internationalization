# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 4.x (`~> 4.2` in the gemspec; GitHub tag `v4.7.0`)
- Accessible dummy tag `v0.18.0`, Trashable dummy tag `v0.11.0` (`require: false`; required by Accessible >= 0.17), Root Switchable dummy tag `v0.9.0`, Metrics dummy tag `v0.2.0` (required by Root Switchable >= 0.7), and Cache dummy tag `v0.5.0` (required by Root Switchable >= 0.9)
- FlatPack dummy tag `v0.1.196`
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
