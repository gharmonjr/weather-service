class ZipLookup < ApplicationRecord
  validates :address, :zip_code, presence: true
  validates :zip_code, format: {with: /\A\d{5}\z/, message: "must be a 5-digit zip code"}
  validates :address, uniqueness: true
end
