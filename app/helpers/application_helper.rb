module ApplicationHelper
  def asset_url asset
    "#{request.protocol}#{request.host_with_port}#{asset_path(asset)}"
  end

  def social_buttons
    # Compute the informations
    account = "coffeesharing"
    description = "Join the official suspended coffee online community. This is a quick and anonymous act of charity"
    url = url_for(only_path:false, lang:I18n.locale)
    image = asset_url 'homeless.jpg'
    if(controller_name == 'places' && action_name == 'show')
      ftitle = "#{@place.name} @ Coffeesharing"
      ttitle = "#{@place.name} is now participating to #suspendedcoffee"
    elsif(controller_name == 'pages')
      ftitle = "#{action_name.capitalize} - Coffee Sharing"
      ttitle = description.sub('suspended coffee', '#suspendedcoffee') + ", "
    else
      ttitle = ftitle = "Coffee Sharing"
    end

    # Compute the links
    t = social_link :twitter, "http://twitter.com/share?text=#{u ttitle}&url=#{u url}&via=#{account}&related=#{account}"
    f = social_link :facebook, "http://www.facebook.com/sharer.php?s=100&p[title]=#{u ftitle}&p[summary]=#{u description}&p[url]=#{u url}&p[images][0]=#{u image}"
    p = social_link :plus, "https://plus.google.com/share?url=#{u url}"

    # return the 3 links
    content_tag :div, t + f + p, class:'share'
  end

private
  def social_link (name, url)
    link_to_function '', "window.open('#{url}','sharer','toolbar=0,status=0,width=548,height=325');", class:name
  end
end
