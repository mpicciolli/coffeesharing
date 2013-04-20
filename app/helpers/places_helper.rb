module PlacesHelper
  @@weekdays = I18n.t(:"date.day_names")

  def shop_title (place)
    size = case place.name.size
      when 0..16  then 60
      when 17..20 then 50
      when 21..26 then 40
      when 27..34 then 30
      else 20
    end
    click = (current_admin_user) ? ' onClick="window.location=\''+edit_admin_place_url(place)+'\';"' : ''
    "<span style=\"font-size:#{size}px;\"#{click}>#{place.name.truncate(50)}</span>".html_safe
  end

  def array_of (sym, place, &block)
    val = place.send(sym)
    unless (val.empty?)
      title = content_tag :b, t(sym) + ' : '
      list = val.map {|e| content_tag :div, block ? block.call(e) : "- #{e}", class: sym.to_s.chop }
      content_tag :p, "#{title}#{list.join}".html_safe
    end
    #<p>
    #  <b>Emails : </b>
    #  <div class="email">xxx@example.com</div>
    #  <div class="email">yyy@example.com</div>
    #</p>
  end

  def block (place, sym, sym2=nil)
    sym2 = sym unless(sym2)
    return '' if (place.send(sym2).blank?)

    title = content_tag :b, t(sym) + ' : '
    content = content_tag :div, simple_format(place.send(sym2).to_s), class: sym2
    content_tag :p, "#{title}#{content}".html_safe
  end

  def extra (place)
    if (place.wifi || place.takeout)
      title = content_tag :b, t(:extra) + ' : '
      txt = ""
      txt+= content_tag(:div, "- #{t(:freewifi)}".html_safe, class:'wifi')    if place.wifi
      txt+= content_tag(:div, "- #{t(:takeaway)}".html_safe, class:'takeout') if place.takeout
      content_tag :p, "#{title}#{txt}".html_safe
    end
  end

  def timerange (title, ranges, extended = false)
    # Print the title
    s = content_tag :b, t(title) + ' : '

    if (extended)
      # Print a 7 days summary (each day + time) using the timeranges stored in the database
      s+= (1..7).inject('') { |s,i|
        n = i%7
        label = content_tag :span, @@weekdays[n], class:'label'
        time  = ranges.map {|e| e.include?(n) ? e.time_to_s : nil }.compact.first ||
                content_tag(:i, t(:closed))
        s += content_tag :div, "#{label}#{time}".html_safe
      }.html_safe
    else
      f = ranges.first
      if (ranges.size == 1 && f.from_day == 0 && f.to_day == 6)
        # One timerange only? print the time for EvERYDAY
        s += content_tag :div, "#{content_tag :span, t(:everyday), class:'label'}#{f.time_to_s}".html_safe
      else
        # More? Print the multiple time ranges
        ranges.each do |e|
          s += content_tag :div, "#{content_tag :span, e.days_to_s, class:'label'}#{e.time_to_s}".html_safe
        end
      end
    end

    # Render the timerange list in a div
    content_tag :div, s, class:'timerange'
  end

  def workhours (place)
    timerange(:open_hours, @place.workhours, true) unless(@place.workhours.empty?)
  end

  def freehours (place)
    timerange(:suspended_hours, @place.freehours) unless(@place.freehours.empty?)
  end
end
