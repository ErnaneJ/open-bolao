class AddStreamUrlAndExternalTsdbToMatches < ActiveRecord::Migration[8.1]
  def change
    # stream_url already added by 20260610222408_add_stream_url_to_matches
    add_column :matches, :external_tsdb_id, :string unless column_exists?(:matches, :external_tsdb_id)
  end
end
