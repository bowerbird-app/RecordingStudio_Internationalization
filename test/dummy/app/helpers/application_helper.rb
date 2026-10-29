module ApplicationHelper
  def dummy_page_nav(title:, back_url: nil, back_label: nil)
    flat_pack_page_nav(
      round: true,
      style: :default,
      back_href: back_url,
      back_tooltip: back_label.presence || t("dummy.nav.home")
    )

    recording_studio_page_nav_right do
      concat recording_studio_root_switch_dropdown(style: :ghost, size: :md)
      concat render(
        FlatPack::Button::Component.new(
          text: t("dummy.nav.sign_out"),
          style: :ghost,
          size: :md,
          url: main_app.destroy_user_session_path,
          data: { turbo_method: :delete }
        )
      )
    end
  end
end
