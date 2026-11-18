# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class RootSwitchDropdownTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "sign in page uses the devise layout and is not squished by the default layout" do
    get new_user_session_path

    assert_response :success
    assert_includes response.body, "admin@admin.com"
    assert_includes response.body, "Password"
    assert_includes response.body, 'data-theme="rounded"'
    refute_includes response.body, "data-recording-studio-default-layout"
    refute_includes response.body, "mt-28"
    refute_includes response.body, "fixed inset-0"
  end

  test "home page renders the root switch dropdown trigger" do
    user = User.find_or_create_by!(email: "root-switch-test@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    sign_in user

    workspace = Workspace.create!(name: "Dropdown Workspace")
    workspace_root = RecordingStudio.create_root_recording!(workspace, actor: user)
    bootstrap_owner_access!(workspace_root, user)

    get root_path

    assert_response :success
    assert_includes response.body, workspace.name
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
  end

  test "root switch page renders with the host default layout" do
    user = User.find_or_create_by!(email: "root-switch-page-test@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    sign_in user

    workspace = Workspace.create!(name: "Switch Page Workspace")
    workspace_root = RecordingStudio.create_root_recording!(workspace, actor: user)
    bootstrap_owner_access!(workspace_root, user)
    grant_view_on_current_root!(user)

    get "/recording_studio_root_switchable/v1/root_switch?scope=all_workspaces"

    assert_response :success
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
    refute_includes response.body, "flat-pack-sidebar-layout"
  end

  test "switching returns to the current page when it is a valid internal route" do
    user = User.find_or_create_by!(email: "root-switch-redirect-test@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    sign_in user

    source_workspace = Workspace.create!(name: "Source Workspace")
    target_workspace = Workspace.create!(name: "Target Workspace")
    target_root_recording = RecordingStudio.create_root_recording!(target_workspace, actor: user)
    bootstrap_owner_access!(target_root_recording, user)
    source_root_recording = RecordingStudio.create_root_recording!(source_workspace, actor: user)
    bootstrap_owner_access!(source_root_recording, user)
    grant_view_on_current_root!(user)

    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: target_root_recording.id,
        return_to: "/docs/install"
      }
    }

    assert_redirected_to "/docs/install"
  end

  test "switching falls back to home when return_to is not a valid internal route" do
    user = User.find_or_create_by!(email: "root-switch-fallback-test@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end

    sign_in user

    source_workspace = Workspace.create!(name: "Fallback Source Workspace")
    target_workspace = Workspace.create!(name: "Fallback Target Workspace")
    target_root_recording = RecordingStudio.create_root_recording!(target_workspace, actor: user)
    bootstrap_owner_access!(target_root_recording, user)
    source_root_recording = RecordingStudio.create_root_recording!(source_workspace, actor: user)
    bootstrap_owner_access!(source_root_recording, user)
    grant_view_on_current_root!(user)

    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: target_root_recording.id,
        return_to: "/not-a-real-route"
      }
    }

    assert_redirected_to "/"
  end

  private

  def bootstrap_owner_access!(recording, actor)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    raise(result.error || "Failed to bootstrap owner access") if result.failure?

    result
  end

  # Seeds already own Client Workspace, and the switcher defaults to the first
  # workspace by name. The page gate checks :view on that current root.
  def grant_view_on_current_root!(actor)
    recording = Workspace.order(:name).filter_map { |workspace| RecordingStudio.root_recording_for(workspace) }.first
    return if recording.nil?
    return if RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)

    result = RecordingStudioAccessible.grant_access(
      recording: recording,
      actor: actor,
      role: :view,
      manager_actor: User.find_by!(email: "admin@admin.com")
    )
    raise(result.error || "Failed to grant view on the current root") if result.failure?

    result
  end
end
