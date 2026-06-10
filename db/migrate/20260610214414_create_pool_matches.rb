class CreatePoolMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :pool_matches do |t|
      t.references :pool, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true

      t.timestamps
    end
    add_index :pool_matches, [:pool_id, :match_id], unique: true
  end
end
