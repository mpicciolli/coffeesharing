class ApplicationController < ActionController::Base
  protect_from_forgery

  def index
    render 'static/index'
  end

  def about
    render 'static/about'
  end

  def contact
    render 'static/contact'
  end

end
