class ApplicationController < ActionController::Base
  before_filter :set_map_markers
  before_filter :set_locale
  protect_from_forgery

private
  def set_locale
    if params[:lang] && I18n.available_locales.include?(params[:lang].to_sym)
      cookies['locale'] = { :value => params[:lang], :expires => 1.year.from_now }
      I18n.locale = params[:lang].to_sym
    elsif cookies['locale'] && I18n.available_locales.include?(cookies['locale'].to_sym)
      I18n.locale = cookies['locale'].to_sym
    #else
      #automatic = http_accept_language.compatible_language_from(I18n.available_locales)
    end
  end

  def set_map_markers
    @places = Place.all.to_a
    @location = @places.map(&:address).to_gmaps4rails
    @countries = @places.group_by {|e| e.address.country }
    @cities = @places.group_by {|e| e.address.city }
    @recent = Place.recent
  end

end
