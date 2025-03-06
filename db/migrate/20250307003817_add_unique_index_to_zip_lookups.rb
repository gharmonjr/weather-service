class AddUniqueIndexToZipLookups < ActiveRecord::Migration[7.2]
  def change
    add_index :zip_lookups, :address, unique: true
  end
end
