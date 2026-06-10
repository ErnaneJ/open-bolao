class CreateSyncLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_logs do |t|
      t.bigint :sync_schedule_id, null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :status, null: false, default: 0
      t.integer :matches_checked, default: 0
      t.integer :matches_updated, default: 0
      t.integer :goals_detected, default: 0
      t.text :error_message
      t.integer :raw_response_size_bytes

      t.timestamps
    end

    add_index :sync_logs, :sync_schedule_id
    add_index :sync_logs, :status
    add_index :sync_logs, :started_at
  end
end
