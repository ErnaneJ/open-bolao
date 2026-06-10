class CreateTournaments < ActiveRecord::Migration[8.1]
  def change
    create_table :tournaments do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :sport, null: false, default: 0
      t.string :season
      t.integer :status, null: false, default: 0
      t.integer :external_provider, null: false, default: 0
      t.jsonb :external_config, default: {}
      t.bigint :created_by_id, null: false

      t.timestamps
    end

    add_index :tournaments, :slug, unique: true
    add_index :tournaments, :created_by_id
    add_index :tournaments, :status
  end
end
