# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_10_222409) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_providers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "base_url"
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "provider_type", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at"
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at"
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "matches", force: :cascade do |t|
    t.integer "away_score"
    t.integer "away_score_et"
    t.integer "away_score_ht"
    t.integer "away_score_penalties"
    t.bigint "away_team_id", null: false
    t.datetime "created_at", null: false
    t.string "external_id"
    t.integer "home_score"
    t.integer "home_score_et"
    t.integer "home_score_ht"
    t.integer "home_score_penalties"
    t.bigint "home_team_id", null: false
    t.datetime "scheduled_at"
    t.bigint "stage_id"
    t.integer "status", default: 0, null: false
    t.string "stream_url"
    t.bigint "tournament_id"
    t.datetime "updated_at", null: false
    t.string "venue"
    t.bigint "winner_team_id"
    t.index ["away_team_id"], name: "index_matches_on_away_team_id"
    t.index ["external_id"], name: "index_matches_on_external_id"
    t.index ["home_team_id"], name: "index_matches_on_home_team_id"
    t.index ["scheduled_at"], name: "index_matches_on_scheduled_at"
    t.index ["stage_id"], name: "index_matches_on_stage_id"
    t.index ["status"], name: "index_matches_on_status"
    t.index ["tournament_id"], name: "index_matches_on_tournament_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "kind", default: 0, null: false
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.datetime "read_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pool_matches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "match_id", null: false
    t.bigint "pool_id", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_pool_matches_on_match_id"
    t.index ["pool_id"], name: "index_pool_matches_on_pool_id"
  end

  create_table "pool_participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "joined_at"
    t.bigint "pool_id", null: false
    t.integer "rank"
    t.integer "rank_previous"
    t.integer "rank_trend", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.integer "total_points", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["pool_id", "user_id"], name: "index_pool_participants_on_pool_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_pool_participants_on_user_id"
  end

  create_table "pools", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.boolean "allow_late_entries", default: false, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.decimal "entry_fee", precision: 10, scale: 2
    t.string "invite_code"
    t.integer "lock_before_minutes", default: 5
    t.bigint "match_id"
    t.integer "max_participants"
    t.string "name", null: false
    t.integer "pool_scope", default: 0, null: false
    t.text "prize_description"
    t.jsonb "scoring_config", default: {}
    t.string "slug", null: false
    t.jsonb "special_bets_config", default: {}
    t.datetime "starts_at"
    t.integer "status", default: 0, null: false
    t.string "timezone"
    t.bigint "tournament_id"
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["admin_id"], name: "index_pools_on_admin_id"
    t.index ["invite_code"], name: "index_pools_on_invite_code", unique: true
    t.index ["match_id"], name: "index_pools_on_match_id"
    t.index ["slug"], name: "index_pools_on_slug", unique: true
    t.index ["status"], name: "index_pools_on_status"
    t.index ["tournament_id"], name: "index_pools_on_tournament_id"
  end

  create_table "special_bets", force: :cascade do |t|
    t.integer "bet_type", null: false
    t.datetime "created_at", null: false
    t.integer "integer_value"
    t.string "player_name"
    t.integer "points_earned", default: 0
    t.bigint "pool_id", null: false
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["pool_id", "user_id", "bet_type"], name: "index_special_bets_on_pool_id_and_user_id_and_bet_type", unique: true
    t.index ["user_id"], name: "index_special_bets_on_user_id"
  end

  create_table "stages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "order_position", default: 0, null: false
    t.integer "stage_type", default: 0, null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_stages_on_tournament_id"
  end

  create_table "sync_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "finished_at"
    t.integer "goals_detected", default: 0
    t.integer "matches_checked", default: 0
    t.integer "matches_updated", default: 0
    t.integer "raw_response_size_bytes"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.bigint "sync_schedule_id", null: false
    t.datetime "updated_at", null: false
    t.index ["started_at"], name: "index_sync_logs_on_started_at"
    t.index ["status"], name: "index_sync_logs_on_status"
    t.index ["sync_schedule_id"], name: "index_sync_logs_on_sync_schedule_id"
  end

  create_table "sync_schedules", force: :cascade do |t|
    t.time "active_from"
    t.time "active_until"
    t.jsonb "active_weekdays"
    t.bigint "api_provider_id"
    t.integer "consecutive_failures", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.integer "interval_seconds", default: 120, null: false
    t.text "last_error_message"
    t.datetime "last_run_at"
    t.datetime "last_success_at"
    t.datetime "paused_until"
    t.boolean "run_only_on_match_days", default: true, null: false
    t.bigint "schedulable_id", null: false
    t.string "schedulable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["api_provider_id"], name: "index_sync_schedules_on_api_provider_id"
    t.index ["enabled"], name: "index_sync_schedules_on_enabled"
    t.index ["schedulable_type", "schedulable_id"], name: "index_sync_schedules_on_schedulable_type_and_schedulable_id", unique: true
  end

  create_table "teams", force: :cascade do |t|
    t.string "country_code"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "flag_url"
    t.string "name", null: false
    t.string "short_name"
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_teams_on_country_code"
    t.index ["name"], name: "index_teams_on_name"
  end

  create_table "tips", force: :cascade do |t|
    t.integer "away_score_tip"
    t.datetime "created_at", null: false
    t.integer "home_score_tip"
    t.datetime "locked_at"
    t.bigint "match_id", null: false
    t.integer "points_earned"
    t.bigint "pool_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["match_id"], name: "index_tips_on_match_id"
    t.index ["pool_id", "user_id", "match_id"], name: "index_tips_on_pool_id_and_user_id_and_match_id", unique: true
    t.index ["user_id"], name: "index_tips_on_user_id"
  end

  create_table "tournament_teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id"
    t.string "group_name"
    t.bigint "team_id", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_tournament_teams_on_team_id"
    t.index ["tournament_id", "team_id"], name: "index_tournament_teams_on_tournament_id_and_team_id", unique: true
  end

  create_table "tournaments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.jsonb "external_config", default: {}
    t.integer "external_provider", default: 0, null: false
    t.string "name", null: false
    t.string "season"
    t.string "slug", null: false
    t.integer "sport", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_tournaments_on_created_by_id"
    t.index ["slug"], name: "index_tournaments_on_slug", unique: true
    t.index ["status"], name: "index_tournaments_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "invitation_token"
    t.bigint "invited_by_id"
    t.integer "locale", default: 0, null: false
    t.string "name", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.string "time_zone", default: "Brasilia"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "attempt_count", default: 0, null: false
    t.datetime "attempted_at"
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.string "event_type", null: false
    t.datetime "next_retry_at"
    t.jsonb "payload", default: {}
    t.text "response_body"
    t.integer "response_code"
    t.datetime "updated_at", null: false
    t.bigint "webhook_endpoint_id", null: false
    t.index ["attempted_at"], name: "index_webhook_deliveries_on_attempted_at"
    t.index ["next_retry_at"], name: "index_webhook_deliveries_on_next_retry_at"
    t.index ["webhook_endpoint_id"], name: "index_webhook_deliveries_on_webhook_endpoint_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.jsonb "events", default: []
    t.integer "last_response_code"
    t.datetime "last_triggered_at"
    t.bigint "owner_id", null: false
    t.string "owner_type", null: false
    t.string "secret_token"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["active"], name: "index_webhook_endpoints_on_active"
    t.index ["owner_type", "owner_id"], name: "index_webhook_endpoints_on_owner_type_and_owner_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "pool_matches", "matches"
  add_foreign_key "pool_matches", "pools"
end
