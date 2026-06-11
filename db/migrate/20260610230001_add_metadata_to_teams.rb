class AddMetadataToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :logo_url,        :string
    add_column :teams, :banner_url,      :string
    add_column :teams, :fanart_url,      :string
    add_column :teams, :primary_color,   :string
    add_column :teams, :formed_year,     :integer
    add_column :teams, :stadium_name,    :string
    add_column :teams, :description,     :text
    add_column :teams, :website,         :string
    add_column :teams, :gender,          :string
  end
end
