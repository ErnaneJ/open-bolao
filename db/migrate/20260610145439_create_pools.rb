class CreatePools < ActiveRecord::Migration[8.1]
  def change
    create_table :pools do |t|
      t.integer :pool_scope, null: false, default: 0
      t.bigint :tournament_id
      t.bigint :match_id
      t.bigint :admin_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.integer :visibility, null: false, default: 0
      t.string :invite_code
      t.decimal :entry_fee, precision: 10, scale: 2
      t.text :prize_description
      t.integer :max_participants
      t.boolean :allow_late_entries, default: false, null: false
      t.integer :lock_before_minutes, default: 5
      t.jsonb :scoring_config, default: {}
      t.jsonb :special_bets_config, default: {}

      t.timestamps
    end

    add_index :pools, :slug, unique: true
    add_index :pools, :invite_code, unique: true
    add_index :pools, :admin_id
    add_index :pools, :tournament_id
    add_index :pools, :match_id
    add_index :pools, :status
  end
end
