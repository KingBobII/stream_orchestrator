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

ActiveRecord::Schema[7.1].define(version: 2026_03_18_220738) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "streams", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "scheduled", null: false
    t.string "visibility", default: "private", null: false
    t.datetime "scheduled_at"
    t.bigint "youtube_channel_id", null: false
    t.string "external_video_id"
    t.jsonb "thumbnails", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sync_status", default: "pending", null: false
    t.text "sync_error"
    t.datetime "synced_at"
    t.index ["external_video_id"], name: "index_streams_on_external_video_id", unique: true
    t.index ["scheduled_at"], name: "index_streams_on_scheduled_at"
    t.index ["status"], name: "index_streams_on_status"
    t.index ["sync_status"], name: "index_streams_on_sync_status"
    t.index ["synced_at"], name: "index_streams_on_synced_at"
    t.index ["visibility"], name: "index_streams_on_visibility"
    t.index ["youtube_channel_id"], name: "index_streams_on_youtube_channel_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "role", default: "stream_operator", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_users_on_uid"
  end

  create_table "youtube_channels", force: :cascade do |t|
    t.string "name", null: false
    t.string "external_id"
    t.text "description"
    t.string "status", default: "inactive", null: false
    t.datetime "published_at"
    t.bigint "owner_id"
    t.string "avatar_url"
    t.string "banner_url"
    t.string "oauth_access_token"
    t.string "oauth_refresh_token"
    t.datetime "oauth_expires_at"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_youtube_channels_on_external_id", unique: true
    t.index ["name"], name: "index_youtube_channels_on_name"
    t.index ["owner_id"], name: "index_youtube_channels_on_owner_id"
  end

  add_foreign_key "streams", "youtube_channels"
  add_foreign_key "youtube_channels", "users", column: "owner_id"
end
