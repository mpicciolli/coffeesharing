ActiveAdmin.register_page "Dashboard" do

  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do
    div :class => "blank_slate_container", :id => "dashboard_default_message" do
      span :class => "blank_slate" do
        span "Welcome to the administration area of Coffee Sharing!"
      end
    end
    br
=begin
    columns do
      column do
        panel "Recent Places" do
          ul do
            Place.last50.map do |place|
              li link_to(place.name, admin_place_path(place))
            end
          end
        end
      end
    end
=end
  end # content
end
