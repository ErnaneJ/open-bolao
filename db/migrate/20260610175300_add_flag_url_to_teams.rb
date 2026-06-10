class AddFlagUrlToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :flag_url, :string
  end
end
