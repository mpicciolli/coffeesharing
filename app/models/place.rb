class Place
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia

  scope :recent, order_by(:created_at => :desc).limit(10)

  field :name
  embeds_one :address
  field :email #replace by an array
  field :phone #replace by an array
  field :website #replace by an array
  field :wifi, type: Boolean
  field :takeout, type: Boolean
  field :notes
  embeds_many :workhours, as:'timable', class_name:'TimeRange' #Use it! not the notes...
  embeds_many :freehours, as:'timable', class_name:'TimeRange' #Use it! not the notes...
end

class Address
  include Mongoid::Document
  include Gmaps4rails::ActsAsGmappable

  embedded_in :place

  acts_as_gmappable :position => :location
  field :gmaps, :type => Boolean
  field :street
  field :postalcode
  field :city
  field :state
  field :country
  field :map_url
  field :location, :type => Array

  def gmaps4rails_address
    "#{self.street}, #{self.city}, #{self.country}"
  end

  def to_s
    s = "#{street}\n"
    s+= "#{postalcode}, " unless(postalcode.blank?)
    s+= "#{city}\n"
    s+= "#{state}\n" unless(state.blank?)
    s+= "#{country}"
  end
end

class TimeRange
  include Mongoid::Document

  embedded_in :timable, polymorphic: true

  field :from_day, type:Integer
  field :to_day, type:Integer
  field :from_time, type:Time
  field :to_time, type:Time
end