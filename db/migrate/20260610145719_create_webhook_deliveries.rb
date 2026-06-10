class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries do |t|
      t.bigint :webhook_endpoint_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, default: {}
      t.integer :response_code
      t.text :response_body
      t.datetime :attempted_at
      t.datetime :delivered_at
      t.integer :attempt_count, null: false, default: 0
      t.datetime :next_retry_at

      t.timestamps
    end

    add_index :webhook_deliveries, :webhook_endpoint_id
    add_index :webhook_deliveries, :attempted_at
    add_index :webhook_deliveries, :next_retry_at
  end
end
