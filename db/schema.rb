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

ActiveRecord::Schema[8.0].define(version: 2026_08_26_064340) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "scenario_clues", force: :cascade do |t|
    t.bigint "scenario_id", null: false
    t.text "content"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_id"], name: "index_scenario_clues_on_scenario_id"
  end

  create_table "scenario_endings", force: :cascade do |t|
    t.bigint "scenario_id", null: false
    t.text "content"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_id"], name: "index_scenario_endings_on_scenario_id"
  end

  create_table "scenario_events", force: :cascade do |t|
    t.bigint "scenario_id", null: false
    t.text "content"
    t.text "trigger_condition"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_id"], name: "index_scenario_events_on_scenario_id"
  end

  create_table "scenario_generation_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "scenario_id"
    t.string "status", default: "processing", null: false
    t.string "openai_response_id"
    t.string "openai_model", null: false
    t.integer "input_tokens", default: 0, null: false
    t.integer "cached_input_tokens", default: 0, null: false
    t.integer "output_tokens", default: 0, null: false
    t.integer "reasoning_tokens", default: 0, null: false
    t.integer "total_tokens", default: 0, null: false
    t.decimal "input_price_per_million_usd", precision: 10, scale: 4, default: "0.0", null: false
    t.decimal "cached_input_price_per_million_usd", precision: 10, scale: 4, default: "0.0", null: false
    t.decimal "output_price_per_million_usd", precision: 10, scale: 4, default: "0.0", null: false
    t.decimal "estimated_cost_usd", precision: 12, scale: 8, default: "0.0", null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.string "openai_status"
    t.string "error_class"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["openai_response_id"], name: "index_scenario_generation_logs_on_openai_response_id", unique: true
    t.index ["scenario_id"], name: "index_scenario_generation_logs_on_scenario_id"
    t.index ["user_id", "created_at"], name: "index_scenario_generation_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_scenario_generation_logs_on_user_id"
  end

  create_table "scenario_npcs", force: :cascade do |t|
    t.bigint "scenario_id", null: false
    t.string "name"
    t.text "description"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_id"], name: "index_scenario_npcs_on_scenario_id"
  end

  create_table "scenario_scene_clues", force: :cascade do |t|
    t.bigint "scenario_scene_id", null: false
    t.bigint "scenario_clue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_clue_id"], name: "index_scenario_scene_clues_on_scenario_clue_id"
    t.index ["scenario_scene_id", "scenario_clue_id"], name: "index_scene_clues_on_scene_and_clue", unique: true
    t.index ["scenario_scene_id"], name: "index_scenario_scene_clues_on_scenario_scene_id"
  end

  create_table "scenario_scene_events", force: :cascade do |t|
    t.bigint "scenario_scene_id", null: false
    t.bigint "scenario_event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_event_id"], name: "index_scenario_scene_events_on_scenario_event_id"
    t.index ["scenario_scene_id", "scenario_event_id"], name: "index_scene_events_on_scene_and_event", unique: true
    t.index ["scenario_scene_id"], name: "index_scenario_scene_events_on_scenario_scene_id"
  end

  create_table "scenario_scene_npcs", force: :cascade do |t|
    t.bigint "scenario_scene_id", null: false
    t.bigint "scenario_npc_id", null: false
    t.text "reaction"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_npc_id"], name: "index_scenario_scene_npcs_on_scenario_npc_id"
    t.index ["scenario_scene_id", "scenario_npc_id"], name: "index_scene_npcs_on_scene_and_npc", unique: true
    t.index ["scenario_scene_id"], name: "index_scenario_scene_npcs_on_scenario_scene_id"
  end

  create_table "scenario_scenes", force: :cascade do |t|
    t.bigint "scenario_id", null: false
    t.string "title"
    t.text "purpose"
    t.integer "estimated_time"
    t.text "read_aloud_text"
    t.text "gm_actions"
    t.text "player_questions"
    t.text "investigation_options"
    t.text "trigger_condition"
    t.text "transition_condition"
    t.text "hint"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_id"], name: "index_scenario_scenes_on_scenario_id"
  end

  create_table "scenarios", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.text "summary"
    t.string "genre"
    t.text "world_setting"
    t.integer "player_count"
    t.integer "play_time"
    t.string "tone"
    t.text "introduction"
    t.text "truth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "story_outline"
    t.string "generation_status", default: "completed", null: false
    t.string "openai_response_id"
    t.index ["user_id"], name: "index_scenarios_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "scenario_generation_count", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.integer "access_count_to_reset_password_page", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
  end

  add_foreign_key "scenario_clues", "scenarios"
  add_foreign_key "scenario_endings", "scenarios"
  add_foreign_key "scenario_events", "scenarios"
  add_foreign_key "scenario_generation_logs", "scenarios", on_delete: :nullify
  add_foreign_key "scenario_generation_logs", "users"
  add_foreign_key "scenario_npcs", "scenarios"
  add_foreign_key "scenario_scene_clues", "scenario_clues"
  add_foreign_key "scenario_scene_clues", "scenario_scenes"
  add_foreign_key "scenario_scene_events", "scenario_events"
  add_foreign_key "scenario_scene_events", "scenario_scenes"
  add_foreign_key "scenario_scene_npcs", "scenario_npcs"
  add_foreign_key "scenario_scene_npcs", "scenario_scenes"
  add_foreign_key "scenario_scenes", "scenarios"
  add_foreign_key "scenarios", "users"
end
