class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.bigint :user_id, null: false
      t.string :notifiable_type
      t.bigint :notifiable_id
      t.integer :kind, null: false, default: 0
      t.string :title, null: false
      t.text :body
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, :user_id
    add_index :notifications, [ :notifiable_type, :notifiable_id ]
    add_index :notifications, :read_at
    add_index :notifications, :created_at
  end
end
