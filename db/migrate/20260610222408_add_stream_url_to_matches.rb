class AddStreamUrlToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :stream_url, :string
  end
end
