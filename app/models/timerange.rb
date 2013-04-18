class TimeRange
  include Mongoid::Document
  include Mongoid::MultiParameterAttributes

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