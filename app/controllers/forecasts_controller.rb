class ForecastsController < ApplicationController
  def new
    @forecast = {}
  end

  def create
    @forecast = WeatherFetcher.fetch_forecast(params[:address]) || {error: "Unable to fetch forecast"}
    @from_cache = @forecast[:cached] || false
    render :new
  end
end
