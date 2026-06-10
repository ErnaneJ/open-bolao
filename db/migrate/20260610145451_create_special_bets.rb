class CreateSpecialBets < ActiveRecord::Migration[8.1]
  def change
    create_table :special_bets do |t|
      t.bigint :pool_id, null: false
      t.bigint :user_id, null: false
      t.integer :bet_type, null: false
      t.bigint :team_id
      t.string :player_name
      t.integer :integer_value
      t.integer :points_earned, default: 0

      t.timestamps
    end

    add_index :special_bets, [:pool_id, :user_id, :bet_type], unique: true
    add_index :special_bets, :user_id
  end
end
