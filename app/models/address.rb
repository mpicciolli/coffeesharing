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
  field :location, :type => Array

  validates_presence_of :country, :city, :street

  def gmaps4rails_address
    "#{self.street}, #{self.city}, #{self.country}"
  end

  def to_s
    s = "#{street}\n"
    s+= "#{state} " unless(state.blank?)
    s+= "#{postalcode}, " unless(postalcode.blank?)
    s+= "#{city}\n"
    s+= "#{country}"
  end
end