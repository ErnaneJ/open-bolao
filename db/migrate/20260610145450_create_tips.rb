class CreateTips < ActiveRecord::Migration[8.1]
  def change
    create_table :tips do |t|
      t.bigint :pool_id, null: false
      t.bigint :user_id, null: false
      t.bigint :match_id, null: false
      t.integer :home_score_tip
      t.integer :away_score_tip
      t.integer :points_earned
      t.datetime :locked_at

      t.timestamps
    end

    add_index :tips, [ :pool_id, :user_id, :match_id ], unique: true
    add_index :tips, :user_id
    add_index :tips, :match_id
  end
end
