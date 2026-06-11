class CreatePoolParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :pool_participants do |t|
      t.bigint :pool_id, null: false
      t.bigint :user_id, null: false
      t.integer :status, null: false, default: 0
      t.integer :total_points, null: false, default: 0
      t.integer :rank
      t.integer :rank_previous
      t.integer :rank_trend, null: false, default: 1
      t.datetime :joined_at

      t.timestamps
    end

    add_index :pool_participants, [ :pool_id, :user_id ], unique: true
    add_index :pool_participants, :user_id
  end
end
