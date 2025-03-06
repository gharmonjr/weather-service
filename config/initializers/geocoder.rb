Geocoder.configure(
  lookup: :geocodio,
  api_key: Rails.application.credentials.dig(:geocodio, :api_key).freeze
)
