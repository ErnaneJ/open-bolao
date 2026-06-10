class AddThumbUrlToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :thumb_url, :string
  end
end
