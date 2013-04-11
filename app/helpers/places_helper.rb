module PlacesHelper
  def shop_title (name)
    size = case name.size
      when 0..16  then 60
      when 17..20 then 50
      when 21..26 then 40
      when 27..34 then 30
      else 20
    end
    "<span style=\"font-size:#{size}px;\">#{name.truncate(50)}</span>".html_safe
  end
end
