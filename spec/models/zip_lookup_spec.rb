require "rails_helper"

RSpec.describe ZipLookup, type: :model do
  describe "validations" do
    it "requires address and zip_code" do
      expect(ZipLookup.new(address: nil, zip_code: "43230")).not_to be_valid
      expect(ZipLookup.new(address: "Columbus, OH", zip_code: nil)).not_to be_valid
      expect(ZipLookup.new(address: "Columbus, OH", zip_code: "43230")).to be_valid
    end

    it "validates zip_code format (5 digits)" do
      expect(ZipLookup.new(address: "Columbus, OH", zip_code: "1234")).not_to be_valid
      expect(ZipLookup.new(address: "Columbus, OH", zip_code: "12345")).to be_valid
      expect(ZipLookup.new(address: "Columbus, OH", zip_code: "123456")).not_to be_valid
    end
  end

  describe "creation" do
    it "creates a record when address is new" do
      allow(Geocoder).to receive(:search).and_return([double(postal_code: "43230")])
      expect {
        WeatherFetcher.fetch_forecast("Columbus, OH")
      }.to change(ZipLookup, :count).by(1)
      expect(ZipLookup.last.address).to eq("Columbus, OH")
      expect(ZipLookup.last.zip_code).to eq("43230")
    end

    it "reuses existing record for known address" do
      ZipLookup.create!(address: "Columbus, OH", zip_code: "43230")
      expect {
        WeatherFetcher.fetch_forecast("Columbus, OH")
      }.not_to change(ZipLookup, :count)
    end

    it "prevents duplicate addresses with validation" do
      ZipLookup.create!(address: "Columbus, OH", zip_code: "43230")
      expect {
        ZipLookup.create!(address: "Columbus, OH", zip_code: "43231") # Use create! to raise error
      }.to raise_error(ActiveRecord::RecordInvalid, /has already been taken/)
    end
  end
end
