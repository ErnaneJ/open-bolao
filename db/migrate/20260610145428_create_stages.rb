class CreateStages < ActiveRecord::Migration[8.1]
  def change
    create_table :stages do |t|
      t.bigint :tournament_id, null: false
      t.string :name, null: false
      t.integer :stage_type, null: false, default: 0
      t.integer :order_position, null: false, default: 0

      t.timestamps
    end

    add_index :stages, :tournament_id
  end
end
