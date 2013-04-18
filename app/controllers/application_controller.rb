class ApplicationController < ActionController::Base
  before_filter :set_map_markers
  before_filter :set_locale
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to admin_dashboard_path, :alert => exception.message
  end

  def current_ability
    @current_ability ||= AdminAbility.new(current_admin_user)
  end

private
  def set_locale
    if params[:lang] && I18n.available_locales.include?(params[:lang].to_sym)
      cookies['locale'] = { :value => params[:lang], :expires => 1.year.from_now }
      I18n.locale = params[:lang].to_sym
    elsif cookies['locale'] && I18n.available_locales.include?(cookies['locale'].to_sym)
      I18n.locale = cookies['locale'].to_sym
    else
      lang = request.compatible_language_from(I18n.available_locales) || I18n.default_locale
      cookies['locale'] = { :value => lang, :expires => 1.year.from_now }
      I18n.locale = lang
    end
  end

  def set_map_markers
    @places = Place.published.to_a
    @location = @places.map(&:address).to_gmaps4rails
    @countries = @places.group_by {|e| e.address.country }
    @cities = @places.group_by {|e| e.address.city }
    @recent = Place.recent
  end

end
