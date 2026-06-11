class AddMetadataToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :referee,      :string
    add_column :matches, :attendance,   :integer
    add_column :matches, :round_number, :integer
    add_column :matches, :season,       :string
    add_column :matches, :city,         :string
  end
end
