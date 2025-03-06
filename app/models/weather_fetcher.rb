class WeatherFetcher
  API_KEY = Rails.application.credentials.dig(:open_weather, :api_key).freeze
  BASE_URL = "https://api.openweathermap.org/data/2.5/forecast".freeze

  def self.fetch_forecast(address)
    zip_lookup = ZipLookup.find_by(address: address)
    if zip_lookup
      zip = zip_lookup.zip_code
    else
      location = Geocoder.search(address).first
      return nil unless location&.postal_code
      zip = location.postal_code
      ZipLookup.create!(address: address, zip_code: zip)
    end

    cached_forecast = Rails.cache.read(zip)
    return cached_forecast.merge(cached: true) if cached_forecast

    response = HTTParty.get(BASE_URL, query: {zip: "#{zip},us", appid: API_KEY, units: "imperial"})
    return nil unless response.success?

    # Today’s forecast (first slot)
    today = response["list"].first["main"]
    # Group by day, compute daily high/low
    daily_forecasts = response["list"]
      .group_by { |slot| Time.at(slot["dt"]).to_date }
      .map { |date, slots|
      next unless Time.at(slots.first["dt"]).to_date > Date.today  # Start tomorrow
      {
        date: slots.first["dt"],
        temperature: slots.map { |s| s["main"]["temp"] }.sum / slots.length,  # Avg temp
        temp_high: slots.map { |s| s["main"]["temp_max"] }.max,              # Daily high
        temp_low: slots.map { |s| s["main"]["temp_min"] }.min               # Daily low
      }
    }
      .compact
      .first(5) # Limit to 5 days

    data = {
      temperature: today["temp"].round,  # Drop decimal
      temp_high: today["temp_max"].round,  # Drop decimal
      temp_low: today["temp_min"].round,   # Drop decimal
      cached: false,
      extended: daily_forecasts.map do |slot|
        {
          time: Time.at(slot[:date]).strftime("%m/%d"),  # e.g., "3/7"
          temperature: slot[:temperature].round,         # Drop decimal
          temp_high: slot[:temp_high].round,            # Drop decimal
          temp_low: slot[:temp_low].round              # Drop decimal
        }
      end
    }
    Rails.cache.write(zip, data, expires_in: 30.minutes)
    data
  end
end
