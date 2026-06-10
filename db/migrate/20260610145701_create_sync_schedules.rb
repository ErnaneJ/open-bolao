class CreateSyncSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_schedules do |t|
      t.string :schedulable_type, null: false
      t.bigint :schedulable_id, null: false
      t.bigint :api_provider_id
      t.boolean :enabled, null: false, default: false
      t.integer :interval_seconds, null: false, default: 120
      t.time :active_from
      t.time :active_until
      t.jsonb :active_weekdays
      t.boolean :run_only_on_match_days, null: false, default: true
      t.datetime :last_run_at
      t.datetime :last_success_at
      t.text :last_error_message
      t.integer :consecutive_failures, null: false, default: 0
      t.datetime :paused_until

      t.timestamps
    end

    add_index :sync_schedules, [:schedulable_type, :schedulable_id], unique: true
    add_index :sync_schedules, :api_provider_id
    add_index :sync_schedules, :enabled
  end
end
