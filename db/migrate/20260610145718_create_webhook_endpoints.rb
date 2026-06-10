class CreateWebhookEndpoints < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_endpoints do |t|
      t.string :owner_type, null: false
      t.bigint :owner_id, null: false
      t.string :url, null: false
      t.string :secret_token
      t.jsonb :events, default: []
      t.boolean :active, null: false, default: true
      t.datetime :last_triggered_at
      t.integer :last_response_code

      t.timestamps
    end

    add_index :webhook_endpoints, [:owner_type, :owner_id]
    add_index :webhook_endpoints, :active
  end
end
