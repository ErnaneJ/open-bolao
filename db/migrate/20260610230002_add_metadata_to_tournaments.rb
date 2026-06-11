class AddMetadataToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :logo_url,    :string
    add_column :tournaments, :badge_url,   :string
    add_column :tournaments, :banner_url,  :string
    add_column :tournaments, :fanart_url,  :string
    add_column :tournaments, :trophy_url,  :string
    add_column :tournaments, :country,     :string
    add_column :tournaments, :description, :text
    add_column :tournaments, :gender,      :string
    add_column :tournaments, :website,     :string
    add_column :tournaments, :formed_year, :integer
  end
end
