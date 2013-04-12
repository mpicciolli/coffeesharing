class Place
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  
  #scope :last50, order_by(:created_at => :desc).limit(50)
  scope :recent, order_by(:created_at => :desc).limit(10)

  field :name
  embeds_one :address
  field :email #replace by an array
    field :emails, type: Array
  field :phone #replace by an array
    field :phones, type: Array
  field :website #replace by an array
    field :websites, type: Array
  field :facebook
  field :google_plus
  field :twitter
  field :foursquare
  field :yelp
  field :wifi, type: Boolean
  field :takeout, type: Boolean
  field :notes
  embeds_many :workhours, :as => :workhour, class_name:'TimeRange'
  embeds_many :freehours, :as => :freehour, class_name:'TimeRange'
  field :validated, type: Boolean, default: false
  
  # Accept nested attributes in the form (and initialize the address automatically)
  accepts_nested_attributes_for :address, :workhours, :freehours
  after_initialize do |place|
    place.build_address unless(place.address)
  end
  
  # Fill everything with facebook informations (quicker ;])
  after_validation do |place|
    if(place.name.blank? && !place.facebook.blank?)
      # Get the infos via the Facebook Graph API
      id = place.facebook.match(/www.facebook.com\/(pages\/)?([^\/]+(\/\d+)?)/)
      json = ActiveSupport::JSON.decode(open("https://graph.facebook.com/#{id[3] || id[2]}"))
      
      # Set the general infos (email and see also not provided by facebook)
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
      
      # Parse the hours and set it correctly
      if (json['hours'])
        weekdays = I18n.t(:"date.abbr_day_names")
        h = json['hours'].inject({}) do |h,(k,v)|
          day = weekdays.index(k[/^[^_]+/].capitalize)
          h[day] ||= Hash.new
          h[day][(k[/_open$/]) ? :start : :end] = Time.parse(v)
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
  end
  
  def workhours_to_h
    # {"Monday"    => "7:00 am - 9:00 pm"
    #  "Tuesday"   => "7:00 am - 9:00 pm"
    #  "Wednesday" => "7:00 am - 9:00 pm"
    #  "Thursday"  => "7:00 am - 9:00 pm"
    #  "Friday"    => "7:00 am - 9:00 pm"
    #  "Saturday"  => "7:00 am - 9:00 pm"
    #  "Sunday"    => nil}
    weekdays = I18n.t(:"date.day_names")
    (1..7).inject({}) do |h,i|
      n = i%6
      h[weekdays[n]] = workhours.map { |e|
        e.include?(n) ? e.time_to_s : nil
      }.compact.first; h
    end
  end
  def freehours_to_h
    f = freehours.first
    if (freehours.size == 1 && f.from_day == 0 && f.to_day == 6)
      # {"Everyday"  => "7:00 am - 5:00 pm"}
      { t(:everyday) => f.time_to_s }
    else
      # {"Mon - Fri" => "7:00 am - 5:00 pm",
      #  "Sat"       => "9:00 am - 5:00 pm"}
      freehours.inject({}) {|h,e| h[e.days_to_s] = e.time_to_s;h }
    end
  end
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
  field :location, :type => Array

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

class TimeRange
  include Mongoid::Document

  embedded_in :workhour, polymorphic: true
  embedded_in :freehour, polymorphic: true

  field :from_day, type:Integer
  field :to_day, type:Integer
  field :from_time, type:Time
  field :to_time, type:Time
  
  def include?(n)
    from_day <= n && to_day >= n
  end
  def days_to_s
    w = I18n.t(:"date.abbr_day_names")
    w[from_day] + " - " + w[to_day]
  end
  def time_to_s
    format = '%H:%M' # '%l:%M %P'
    from_time.strftime(format).strip + " - " + to_time.strftime(format).strip
  end
end
