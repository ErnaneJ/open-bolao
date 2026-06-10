class AddStreamUrlAndExternalTsdbToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :stream_url, :string
    add_column :matches, :external_tsdb_id, :string
  end
end
