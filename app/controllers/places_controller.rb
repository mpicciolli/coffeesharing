class PlacesController < ApplicationController
  skip_before_filter :set_map_markers, :only => [:show]

  # GET /places
  def index
    @places = Place.published.to_a
    @countries = @places.sort_by {|e| e.address.city }.group_by {|e| e.address.country }
    @cities = @places.group_by {|e| e.address.city }

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /places/1
  # GET /places/1.json
  def show
    @place = Place.where(id: params[:id], validated:true).first
    if @place
      @location = @place.address.to_gmaps4rails

      respond_to do |format|
        format.html # show.html.erb
        #format.json { render json: @place }
      end
    else
      render :file => "#{Rails.root}/public/404.html", :status => :not_found, layout:nil
    end
  end
end
