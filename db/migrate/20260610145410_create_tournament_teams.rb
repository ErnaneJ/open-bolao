class CreateTournamentTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_teams do |t|
      t.bigint :tournament_id, null: false
      t.bigint :team_id, null: false
      t.string :group_name
      t.string :external_id

      t.timestamps
    end

    add_index :tournament_teams, [:tournament_id, :team_id], unique: true
    add_index :tournament_teams, :team_id
  end
end
