 Mongoid::Userstamp.configure do |c|
   c.user_reader = :current_admin_user
   c.user_model = :admin_user

   c.created_column = :created_by
   c.created_accessor = :creator

   c.updated_column = :updated_by
   c.updated_accessor = :updator
 end