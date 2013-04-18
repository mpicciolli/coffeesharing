ActiveAdmin.register Place do
  scope :all, default:true
  scope :pending               do |p| p.where(validated:false) end
  scope :published             do |p| p.where(validated:true) end
  scope :without_facebook_page do |p| p.any_of({facebook: nil},{facebook: ''}) end

  #filter :name

  index do
    selectable_column
    column :status         do |p| status_tag(p.validated ? 'Published' : 'Pending', p.validated ? :ok : :error) end
    column :name
    column :city           do |p| p.address.city end
    column :country        do |p| p.address.country end
    column :created_at
    default_actions
  end

  form do |f|
    f.inputs "Place" do
      f.input :name, required:false, label:"Name*"
      f.input :validated, :as => :radio
    end
    f.inputs name:'Address', :for => :address do |ff|
      ff.input :street, required:false, label:"Street*"
      ff.input :postalcode
      ff.input :city
      ff.input :state
      ff.input :country, required:false, label:"Country*"
    end
    f.inputs name:'Contact' do
      f.input :phone, :hint => 'Please use commas if there is more than one. (eg. "+33123456789, 0123456789, 01 23 45 67 89")'
      f.input :email, :hint => 'Please use commas if there is more than one. (eg. "foo@bar.com, bar@foo.com")'
      f.input :website, :hint => 'Please use commas if there is more than one. (eg. "www.example.com, www.assoc.org")'
      f.input :facebook, :hint => 'If you submit the form with a Facebook URL but nothing in the field Name, all the informations (except email) will be filled automatically.'
      f.input :google_plus
      f.input :youtube
      f.input :twitter
      f.input :foursquare
      f.input :yelp
    end
    f.inputs name:'Open hour (work hours)' do
      f.has_many :workhours do |ff|
        ff.input :from_day, :as => :select, :collection => I18n.t(:"date.day_names").each.with_index.to_a
        ff.input :to_day, :as => :select, :collection => I18n.t(:"date.day_names").each.with_index.to_a#, hint: 'Note that the following time is bind to UTC timezone...'
        ff.input :from_time, :as => :time_select, :minute_step => 15
        ff.input :to_time, :as => :time_select, :minute_step => 15
      end
    end
    f.inputs name:'Serving suspended coffee only at...' do
      f.has_many :freehours do |ff|
        ff.input :from_day, :collection => I18n.t(:"date.day_names").each.with_index.to_a
        ff.input :to_day, :collection => I18n.t(:"date.day_names").each.with_index.to_a#, hint: 'Note that the following time is bind to UTC timezone...'
        ff.input :from_time, :as => :time_select, :minute_step => 15
        ff.input :to_time, :as => :time_select, :minute_step => 15
      end
    end
    f.inputs name:'Complementary information' do
      f.input :notes, :as => :text
      f.input :wifi, :as => :boolean
      f.input :takeout, :as => :boolean
    end
    f.actions
  end

  show :title => :title do
    panel "Shop information" do
      attributes_table_for place do
        row 'Status'             do status_tag(place.validated ? 'Published' : 'Pending request', place.validated ? :ok : :error) end
        row :name
        row 'Address'            do simple_format place.address.to_s end
        row 'Description'        do simple_format place.notes end
        row :takeout
        row :wifi
        row 'Open hours'         do workhours(place) end
        row 'S.C. serving hours' do freehours(place) end
      end
    end
    panel "Contact information" do
      attributes_table_for place do
        row :email
        row :phone
        row :website
        row :facebook
        row :google_plus
        row :youtube
        row :twitter
        row :foursquare
        row :yelp
      end
    end
    panel "Hidden" do
      attributes_table_for place do
        row :created_at
        row 'Created by'         do (place.creator) ? place.creator.title_with_details : "GUEST" end
        row :updated_at
        row 'Updated by'         do (place.updator) ? place.updator.title_with_details : "GUEST" end
      end
      #active_admin_comments
    end
  end

  batch_action :publish do |selection|
    Place.find(selection).each do |p|
      p.publish!
    end
    redirect_to collection_path, :notice => "The #{selection.size} selected items are now published!"
  end
  batch_action :unpublish do |selection|
    Place.find(selection).each do |p|
      p.publish!(false)
    end
    redirect_to collection_path, :notice => "The #{selection.size} selected items are now no more visible on the website."
  end
  batch_action :update_with_facebook, :confirm => "Are you sure? It may erase some informations!" do |selection|
    Place.find(selection).each do |p|
      Place.fill_with_facebook(p)
    end
    redirect_to collection_path, :notice => "The #{selection.size} selected items are now published!"
  end
  batch_action :update_worktime_with_facebook do |selection|
    Place.find(selection).each do |p|
      Place.fill_with_facebook(p, false)
    end
    redirect_to collection_path, :notice => "The #{selection.size} selected items are now published!"
  end
  action_item only:[:show] do
    link_to "New Place", new_admin_place_path
  end

  collection_action :index, :method => :get do
    # Get the current admin user, and scope the places list (order by creation date, most recent first)
    user = current_active_admin_user
    scope = Place.scoped.order_by(:created_at.desc)

    # Moderators are limited to see only some countries & cities (but can edit others too).
    scope = scope.any_of({:'address.country'.in => user.countries},
                         {:'address.city'.in => user.cities}) unless(user.role?(:admin))

    # Quick fix a d**n bug with activeadmin SCOPED not working properly
    scope = scope.where(validated:false) if(params[:scope] == 'pending')
    scope = scope.where(validated:true) if(params[:scope] == 'published')
    scope = scope.any_of({facebook: nil},{facebook: ''}) if(params[:scope] == 'without_facebook_page')

    # Blah.
    @collection = scope.page(params[:page]) if params[:q].blank?
    @collection_before_scope = @collection
    @search = scope.metasearch(clean_search_params(params[:q]))
  end
end