class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.bigint :tournament_id
      t.bigint :stage_id
      t.bigint :home_team_id, null: false
      t.bigint :away_team_id, null: false
      t.datetime :scheduled_at
      t.integer :status, null: false, default: 0
      t.integer :home_score
      t.integer :away_score
      t.integer :home_score_ht
      t.integer :away_score_ht
      t.integer :home_score_et
      t.integer :away_score_et
      t.integer :home_score_penalties
      t.integer :away_score_penalties
      t.bigint :winner_team_id
      t.string :venue
      t.string :external_id

      t.timestamps
    end

    add_index :matches, :tournament_id
    add_index :matches, :stage_id
    add_index :matches, :home_team_id
    add_index :matches, :away_team_id
    add_index :matches, :scheduled_at
    add_index :matches, :status
    add_index :matches, :external_id
  end
end
