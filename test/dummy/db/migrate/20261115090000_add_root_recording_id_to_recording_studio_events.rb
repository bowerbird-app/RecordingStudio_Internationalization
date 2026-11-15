# frozen_string_literal: true

class AddRootRecordingIdToRecordingStudioEvents < ActiveRecord::Migration[8.1]
  def up
    add_column :recording_studio_events, :root_recording_id, :uuid unless column_exists?(:recording_studio_events, :root_recording_id)

    execute <<~SQL.squish
      UPDATE recording_studio_events AS events
      SET root_recording_id = COALESCE(recordings.root_recording_id, recordings.id)
      FROM recording_studio_recordings AS recordings
      WHERE recordings.id = events.recording_id
        AND events.root_recording_id IS NULL
    SQL

    change_column_null :recording_studio_events, :root_recording_id, false
    add_foreign_key :recording_studio_events, :recording_studio_recordings, column: :root_recording_id unless foreign_key_exists?(:recording_studio_events, :recording_studio_recordings, column: :root_recording_id)

    unless index_exists?(:recording_studio_events, %i[root_recording_id occurred_at created_at id], name: "index_rs_events_on_root_and_timeline")
      add_index :recording_studio_events,
                %i[root_recording_id occurred_at created_at id],
                order: { occurred_at: :desc, created_at: :desc, id: :desc },
                name: "index_rs_events_on_root_and_timeline"
    end

    return if index_exists?(:recording_studio_events, %i[impersonator_type impersonator_id occurred_at], name: "index_rs_events_on_impersonator_and_occurred_at")

    add_index :recording_studio_events,
              %i[impersonator_type impersonator_id occurred_at],
              name: "index_rs_events_on_impersonator_and_occurred_at"
  end

  def down
    remove_foreign_key :recording_studio_events, column: :root_recording_id if foreign_key_exists?(:recording_studio_events, column: :root_recording_id)
    remove_index :recording_studio_events, name: "index_rs_events_on_root_and_timeline" if index_exists?(:recording_studio_events, name: "index_rs_events_on_root_and_timeline")
    remove_index :recording_studio_events, name: "index_rs_events_on_impersonator_and_occurred_at" if index_exists?(:recording_studio_events, name: "index_rs_events_on_impersonator_and_occurred_at")
    remove_column :recording_studio_events, :root_recording_id if column_exists?(:recording_studio_events, :root_recording_id)
  end
end
