require 'rails_helper'

RSpec.describe WeatherFetcher, type: :model do
  describe '.fetch_forecast' do
    let(:mock_response) do
      {
        "list" => [
          { "dt" => Time.now.to_i, "main" => { "temp" => 33.6, "temp_max" => 36.2, "temp_min" => 31.8 } },
          { "dt" => (Time.now + 1.day).change(hour: 12).to_i, "main" => { "temp" => 35.33, "temp_max" => 38.5, "temp_min" => 33.1 } },
          { "dt" => (Time.now + 1.day).change(hour: 15).to_i, "main" => { "temp" => 36.0, "temp_max" => 37.0, "temp_min" => 32.0 } },
          { "dt" => (Time.now + 2.days).change(hour: 12).to_i, "main" => { "temp" => 36.19, "temp_max" => 39.5, "temp_min" => 34.2 } },
          { "dt" => (Time.now + 3.days).change(hour: 12).to_i, "main" => { "temp" => 41.72, "temp_max" => 43.0, "temp_min" => 39.0 } },
          { "dt" => (Time.now + 4.days).change(hour: 12).to_i, "main" => { "temp" => 47.25, "temp_max" => 48.5, "temp_min" => 45.0 } },
          { "dt" => (Time.now + 5.days).change(hour: 12).to_i, "main" => { "temp" => 58.6, "temp_max" => 60.0, "temp_min" => 56.0 } }
        ]
      }
    end

    it 'fetches and caches forecast for a new address' do
      allow(Geocoder).to receive(:search).and_return([double(postal_code: '43230')])
      # Fix: Stub [] method directly
      response = double("HTTParty::Response", success?: true)
      allow(response).to receive(:[]).with("list").and_return(mock_response["list"])
      allow(HTTParty).to receive(:get).and_return(response)
      forecast = WeatherFetcher.fetch_forecast('Columbus, OH')
      expect(forecast[:temperature]).to eq(34)
      expect(forecast[:temp_high]).to eq(36)
      expect(forecast[:temp_low]).to eq(32)
      expect(forecast[:cached]).to be false
      expect(forecast[:extended].length).to eq(5)
      expect(forecast[:extended][0][:time]).to eq("03/07")
      expect(forecast[:extended][0][:temperature]).to eq(36)
      expect(forecast[:extended][0][:temp_high]).to eq(39)
      expect(forecast[:extended][0][:temp_low]).to eq(32)
      expect(ZipLookup.find_by(address: 'Columbus, OH').zip_code).to eq('43230')
    end

    it 'uses stored zip and cached weather if available' do
      ZipLookup.create!(address: 'Columbus, OH', zip_code: '43230')
      cached_data = { temperature: 75, temp_high: 78, temp_low: 70, cached: true, extended: [] }
      allow(Rails.cache).to receive(:read).with('43230').and_return(cached_data)
      forecast = WeatherFetcher.fetch_forecast('Columbus, OH')
      expect(forecast[:temperature]).to eq(75)
      expect(forecast[:cached]).to be true
    end

    it 'returns nil for invalid address' do
      allow(Geocoder).to receive(:search).and_return([])
      expect(WeatherFetcher.fetch_forecast('Invalid')).to be_nil
    end

    it 'returns nil on API failure' do
      allow(Geocoder).to receive(:search).and_return([double(postal_code: '43230')])
      allow(HTTParty).to receive(:get).and_return(double(success?: false, code: 401))
      expect(WeatherFetcher.fetch_forecast('Columbus, OH')).to be_nil
    end

    it 'refetches when cache expires' do
      ZipLookup.create!(address: 'Columbus, OH', zip_code: '43230')
      Rails.cache.write('43230', { temperature: 75, temp_high: 78, temp_low: 70, extended: [] }, expires_in: 31.minutes)
      allow(Geocoder).to receive(:search).and_return([double(postal_code: '43230')])
      response = double("HTTParty::Response", success?: true)
      allow(response).to receive(:[]).with("list").and_return(mock_response["list"])
      allow(HTTParty).to receive(:get).and_return(response)
      travel 31.minutes do
        forecast = WeatherFetcher.fetch_forecast('Columbus, OH')
        expect(forecast[:temperature]).to eq(34)
        expect(forecast[:cached]).to be false
      end
    end
  end
end
