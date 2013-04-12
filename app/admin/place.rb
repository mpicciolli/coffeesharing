ActiveAdmin.register Place do
  scope :all
  scope :pending, default:true do |p| p.where(validated:false) end
  scope :published do |p| p.where(validated:true) end
  index do
    column :status         do |p| status_tag(p.validated ? 'Published' : 'Pending', p.validated ? :ok : :error) end
    column :name
    column :city           do |p| p.address.city end
    column :country        do |p| p.address.country end
    column :created_at
    default_actions
  end

  form do |f|
    f.inputs "Place" do
      f.input :name
      f.input :validated, :as => :radio
    end
    f.inputs name:'Address', :for => :address do |ff|
      ff.input :street
      ff.input :postalcode
      ff.input :city
      ff.input :state
      ff.input :country#, :as => :country
    end
    f.inputs name:'Contact' do
      f.input :phone, :as => :phone
      f.input :email, :as => :email
      #f.has_many :emails do |ff|
      #end
      f.input :website, :as => :url
      f.input :facebook, :as => :url
      f.input :google_plus, :as => :url
      f.input :twitter
      f.input :foursquare, :as => :url
      f.input :yelp, :as => :url
    end
    f.inputs name:'Open hour (work hours)' do
      f.has_many :workhours do |ff|
        ff.input :from_day, :as => :select, :collection => I18n.t(:"date.day_names").each.with_index.to_a
        ff.input :to_day, :as => :select, :collection => I18n.t(:"date.day_names").each.with_index.to_a
        ff.input :from_time, :as => :time_select
        ff.input :to_time, :as => :time_select
      end
    end
    f.inputs name:'Serving suspended coffee only at...' do
      f.has_many :freehours do |ff|
        ff.input :from_day, :collection => I18n.t(:"date.day_names").each.with_index.to_a
        ff.input :to_day, :collection => I18n.t(:"date.day_names").each.with_index.to_a
        ff.input :from_time, :as => :time_select
        ff.input :to_time, :as => :time_select
      end
    end
    f.inputs name:'Complementary information' do
      f.input :notes, :as => :text
      f.input :wifi, :as => :boolean
      f.input :takeout, :as => :boolean
    end
    f.actions
  end
  
  collection_action :index, :method => :get do
    scope = Place.scoped
    @collection = scope.page() if params[:q].blank?
    @collection_before_scope = @collection
    @search = scope.metasearch(clean_search_params(params[:q]))
  end
end