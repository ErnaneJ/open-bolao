class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email

      t.string :name, null: false, default: ""
      t.integer :role, null: false, default: 0
      t.integer :locale, null: false, default: 0
      t.string :invitation_token
      t.bigint :invited_by_id
      t.string :time_zone, default: "Brasilia"

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :invitation_token, unique: true
    add_index :users, :invited_by_id
  end
end
