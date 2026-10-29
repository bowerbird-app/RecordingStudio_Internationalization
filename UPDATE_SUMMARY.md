# Recording Studio kit pin update

Copied addons now start on the Support host-kit floor.

- Gemspec: `add_dependency "recording_studio", ">= 4.2", "< 7"`
- Dummy GitHub tags: Recording Studio `v6.3.0`, Accessible `v0.23.1`, Trashable `v0.12.0`, Root Switchable `v0.11.2`, Metrics `v0.7.0`, Cache `v0.6.0`, FlatPack `v0.1.329`, Users `v0.26.5`, Admin `v2.5.1`, Attachable `v0.22.0`
- Root and dummy Rails locks both `8.1.4`
- Authenticated dummy layout: `recording_studio_layout` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
- Optional example mixin: `include RecordingStudio::Capabilities::Example.to(**opts)` wraps `RecordingStudio::Capabilities.include_for`. Installing the gem does not enable it globally.
