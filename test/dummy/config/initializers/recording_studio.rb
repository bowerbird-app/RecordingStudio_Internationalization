# frozen_string_literal: true

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes)
  config.recordable_types = [ "Workspace", "Folder", "Page" ]

  # Require each configured ActiveRecord type to call recording_studio_recordable.
  config.require_recordable_declarations = true

  # Shown in the shared default layout title fallback.
  config.app_name = "Addon Template" if config.respond_to?(:app_name=)

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }

  # This host has no write authorizer. Core 7 refuses record! and
  # create_root_recording! unless one is set or this opt-out is on.
  config.allow_unauthorized_writes = true

  # Emit ActiveSupport::Notifications events
  config.event_notifications_enabled = true

  # Idempotency behavior for log_event!
  config.idempotency_mode = :return_existing # or :raise

  # Recordable duplication strategy for revisions
  config.recordable_dup_strategy = :dup
end
