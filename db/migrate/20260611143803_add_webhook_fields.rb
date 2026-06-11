class AddWebhookFields < ActiveRecord::Migration[8.1]
  def change
    # Per-pool webhook master switch + metadata sent in every payload
    add_column :pools, :webhook_enabled, :boolean, default: false, null: false
    add_column :pools, :webhook_metadata, :jsonb, default: {}

    # Allow GET webhooks in addition to the default POST
    add_column :webhook_endpoints, :http_method, :string, default: "POST", null: false
  end
end
