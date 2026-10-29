# frozen_string_literal: true

class DocsController < ApplicationController
  def install
  end

  def configuration
    render :config
  end

  def recordable_types
    RecordingStudio.validate_recordable_declarations!

    @recordable_types = RecordingStudio.recordable_declarations.values.sort_by(&:type).map do |declaration|
      normalize_recordable_declaration(declaration)
    end
  end

  def recordings_tree
    root_recording = current_root_recording
    recordings = recordings_for_root(root_recording)
    recordings_by_parent_id = recordings.group_by(&:parent_recording_id)
    visible_root = recordings.find { |recording| recording.id == root_recording&.id }

    @recording_tree = Array(visible_root).map do |recording|
      build_recording_node(recording, recordings_by_parent_id)
    end
  end

  def gem_views
    engine_root = RecordingStudioInternationalization::Engine.root
    prefix = "#{engine_root}/"

    @engine_views = Dir.glob(engine_root.join("app/views/recording_studio_internationalization/**/*.erb").to_s)
      .sort
      .map { |path| path.delete_prefix(prefix) }
  end

  def methods
  end

  private

  def normalize_recordable_declaration(declaration)
    {
      name: declaration.type,
      label: declaration.label,
      root: declaration.root?,
      allowed_parent_types: RecordingStudio.allowed_parent_types_for(declaration.type),
      recordings_count: RecordingStudio::Recording.where(recordable_type: declaration.type).count,
      recordables_count: count_recordables_for(declaration.type)
    }
  end

  def count_recordables_for(type_name)
    recordable_class = type_name.safe_constantize
    return 0 unless recordable_class&.<= ActiveRecord::Base
    return 0 unless recordable_class.table_exists?

    recordable_class.count
  rescue ActiveRecord::ActiveRecordError
    0
  end

  def recordings_for_root(root_recording)
    return [] if root_recording.nil?

    RecordingStudio::Recording.includes(:recordable)
      .where(root_recording_id: root_recording.id)
      .reorder(:created_at, :id)
      .to_a
  end

  def build_recording_node(recording, recordings_by_parent_id)
    {
      label: recording_label(recording),
      children: recordings_by_parent_id.fetch(recording.id, []).map do |child_recording|
        build_recording_node(child_recording, recordings_by_parent_id)
      end
    }
  end

  def recording_label(recording)
    recordable = recording.recordable
    type_label = RecordingStudio.recordable_type_label(recordable || recording.recordable_type)
    "#{type_label}: #{RecordingStudio.recordable_name(recordable)}"
  end
end
