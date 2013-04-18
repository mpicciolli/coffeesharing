ActiveAdmin.register AdminUser do
  menu :if => proc{ can?(:manage, AdminUser) }
  controller.authorize_resource

  index do
    column :title_with_details
    column :current_sign_in_at
    column :sign_in_count
    default_actions
  end

  #filter :email

  form do |f|
    f.inputs "Admin Details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :first_name
      f.input :last_name
      f.input :role, :collection => AdminUser::ROLES.each.with_index.to_a
      f.input :countries_list
      f.input :cities_list
    end
    f.actions
  end

  show :title => :title do
    panel "Admin" do
      attributes_table_for admin_user do
        row :first_name
        row :last_name
        row 'Role'              do AdminUser::ROLES[admin_user.role].capitalize end
        unless(admin_user.role?(:admin))
          row 'Countries'       do admin_user.countries.to_sentence end
          row 'Cities'          do admin_user.cities.to_sentence end
        end
      end
    end
    panel "Tracking" do
      attributes_table_for admin_user do
        row :sign_in_count
        row :current_sign_in_at
        row :last_sign_in_at
        row :current_sign_in_ip
        row :last_sign_in_ip
      end
    end
    panel "Hidden" do
      attributes_table_for admin_user do
        row :created_at
        row 'Created by'        do (admin_user.creator) ? admin_user.creator.title_with_details : "god" end
        row :updated_at
        row 'Updated by'        do (admin_user.updator) ? admin_user.updator.title_with_details : "god" end
      end
    end
  end

  # Fix another d**n activeadmin/cancan integration bug?
  controller do
    def authorize!(action, subject = nil)
      unless active_admin_authorization.authorized?(action, subject)
        raise ActiveAdmin::AccessDenied.new(current_active_admin_user, action, subject)
      end
    end
  end
end
