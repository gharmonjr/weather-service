class CreateZipLookups < ActiveRecord::Migration[7.2]
  def change
    create_table :zip_lookups do |t|
      t.string :address
      t.string :zip_code

      t.timestamps
    end
  end
end
