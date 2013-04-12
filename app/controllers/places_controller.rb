class PlacesController < ApplicationController
  skip_before_filter :set_map_markers, :only => [:show]
  
  # GET /places
  # GET /places.json
  def index
    @places = Place.all.to_a
    @countries = @places.sort_by {|e| e.address.city }.group_by {|e| e.address.country }
    @cities = @places.group_by {|e| e.address.city }

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @places }
    end
  end

  # GET /places/1
  # GET /places/1.json
  def show
    @place = Place.find(params[:id])
    @location = @place.address.to_gmaps4rails

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @place }
    end
  end
end
