require 'timerange'
require 'address'
require 'net/http'
require 'open-uri'
require 'nokogiri'

class Place
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Userstamp
  include Mongoid::Paranoia

  scope :recent, where(validated: true).order_by(:created_at => :desc).limit(10)
  scope :requested, where(validated: false)
  scope :published, where(validated: true)

  field :name
  embeds_one :address
  field :emails, type: Array
  field :phones, type: Array
  field :websites, type: Array
  field :facebook
  field :google_plus
  field :youtube
  field :twitter
  field :foursquare
  field :yelp
  field :wifi, type: Boolean
  field :takeout, type: Boolean
  field :notes
  embeds_many :workhours, :as => :workhour, class_name:'TimeRange'
  embeds_many :freehours, :as => :freehour, class_name:'TimeRange'
  field :validated, type: Boolean, default: false

  validates_presence_of :name

  # Some helpers
  def title
    "#{name} (#{address.city}, #{address.country})"
  end
  def publish!(validate = true)
    write_attribute(:validated, validate)
    save
  end
  # Hosted on Heroku? Let's earn some bytes :)
  def email
    emails.join(", ") if(emails)
  end
  def email=(value)
    write_attribute(:emails, (value.class == String) ? value.strip.split(/\s*,\s*/) : [])
  end
  def phone
    phones.join(", ") if(phones)
  end
  def phone=(value)
    write_attribute(:phones, (value.class == String) ? value.strip.split(/\s*[,\/]\s*/) : [])
  end
  def website=(value)
    write_attribute(:websites, (value.class == String) ? value.strip.split(/\s*,\s*/).map {|e| e.sub(/^https?:\/\//, '').sub(/\/$/, '') } : [])
  end
  def website
    websites.join(", ") if(websites)
  end
  def google_plus=(value)
    write_attribute(:google_plus, (value.class == String) ? value.strip.sub(/^https?:\/\/plus.google.com\/([^?#\/]+).*$/, '\1') : value)
  end
  def google_plus
    value = read_attribute(:google_plus)
    (value.blank?) ? nil : "https://plus.google.com/#{value}/about"
  end
  def youtube=(value)
    write_attribute(:youtube, (value.class == String) ? value.strip.sub(/^https?:\/\/(www.)?youtube.com\/user\/([^?#\/]+).*$/, '\2') : value)
  end
  def youtube
    value = read_attribute(:youtube)
    (value.blank?) ? nil : "http://www.youtube.com/user/#{value}"
  end
  def twitter=(value)
    write_attribute(:twitter, (value.class == String) ? value.strip.sub(/^(https?:\/\/(www.)?twitter.com\/|@)([a-zA-Z0-9_]+).*$/, '\3') : value)
  end
  def twitter
    value = read_attribute(:twitter)
    (value.blank?) ? nil : "http://twitter.com/#{value}"
  end
  def twitter_name
    value = read_attribute(:twitter)
    (value.blank?) ? nil : "@#{value}"
  end
  def foursquare=(value)
    write_attribute(:foursquare, (value.class == String) ? value.strip.sub(/^https?:\/\/(www.)?foursquare.com\/([^?#]+)$/, '\2') : value)
  end
  def foursquare
    value = read_attribute(:foursquare)
    (value.blank?) ? nil : "https://foursquare.com/#{value}"
  end
  def yelp=(value)
    write_attribute(:yelp, (value.class == String) ? value.strip.sub(/^https?:\/\/(www\.)?yelp\.[^\/]+\/biz\/([^?#\/]+).*$/, '\2') : value)
  end
  def yelp
    value = read_attribute(:yelp)
    (value.blank?) ? nil : "http://www.yelp.com/biz/#{value}"
  end

  # Accept nested attributes in the form (and initialize the address automatically)
  accepts_nested_attributes_for :address, :workhours, :freehours
  after_initialize do |place|
    place.build_address unless(place.address)
  end

  # Fill everything with facebook informations (quicker ;])
  before_validation do |place|
    fill_with_facebook(place) if(place.name.blank?)
    place.fill_with_googleplus if(place.name.blank?)
    place.fill_with_yelp if(place.name.blank?)
  end

  def self.fill_with_facebook(place, general = true, hours = true)
    return if(place.facebook.blank?)

    # Get the infos via the Facebook Graph API
    id = place.facebook.match(/www.facebook.com\/(pages\/)?([^\/]+(\/\d+)?)/)
    json = ActiveSupport::JSON.decode(open("https://graph.facebook.com/#{id[3] || id[2]}"))

    # Set the general infos (email and see also not provided by facebook)
    if general
      place.facebook           = json['link']                                                  if(json['link'])
      place.name               = json['name']                                                  if(json['name'])
      place.notes              = json['description']                                           if(json['description'])
      place.address.street     = json['location']['street']                                    if(json['location'])
      place.address.city       = json['location']['city']                                      if(json['location'])
      place.address.state      = json['location']['state']                                     if(json['location'])
      place.address.country    = json['location']['country']                                   if(json['location'])
      place.address.postalcode = json['location']['zip']                                       if(json['location'])
      place.address.location   = [json['location']['latitude'], json['location']['longitude']] if(json['location'])
      place.website            = json['website']                                               if(json['website'])
      place.phone              = json['phone']                                                 if(json['phone'])
      place.takeout            = json['restaurant_services']['takeout'] == 1                   if(json['restaurant_services'])
      place.validated          = false
    end

    # Parse the hours and set it correctly
    if (json['hours'] && hours)
      weekdays = I18n.t(:"date.abbr_day_names")
      h = json['hours'].inject({}) do |h,(k,v)|
        day = weekdays.index(k[/^[^_]+/].capitalize)
        h[day] ||= Hash.new
        h[day][(k[/_open$/]) ? :start : :end] = Time.zone.parse(v)
        h
      end
      place.workhours = (0..7).inject([[],[-1,{}]]) do |(a,(startday,last)),day|
        if (h[day] != last)
          if (startday > 0 && last && last[:start] && last[:end])
            a << TimeRange.new(from_day:startday,to_day:day-1,from_time:last[:start],to_time:last[:end])
          end
          last = h[day]
          startday = day
        end
        [a,[startday,last]]
      end.first
    end
  end

  def fill_with_googleplus (place)
    return if(google_plus.blank?)
    # @TODO: Google plus scrapper
  end

  def fill_with_yelp (place)
    return if(yelp.blank?)

    # Get the infos via the YELP website
    useragent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31'
    src = Nokogiri::HTML(open(place.yelp, 'User-Agent' => useragent))

    # @TODO: [DEBUG] the general infos
    p src.search('//h1').text.strip
    p src.search('//address').text.strip
    p src.search('#bizPhone').text
    p src.search('#bizUrl').text.strip
    p src.search('.attr-BusinessHours').text.gsub("\t", '')
    p src.search('.attr-WiFi').text
    p src.search('.attr-RestaurantsTakeOut').text
    p src.search('.attr-WheelchairAccessible').text
    p src.search('#static_map').first.attributes['src'].value
  end

end
