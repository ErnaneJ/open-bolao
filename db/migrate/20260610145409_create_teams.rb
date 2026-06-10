class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :short_name
      t.string :country_code
      t.bigint :created_by_id

      t.timestamps
    end

    add_index :teams, :country_code
    add_index :teams, :name
  end
end
