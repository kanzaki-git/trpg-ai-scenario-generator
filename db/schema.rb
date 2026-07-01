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

ActiveRecord::Schema[8.0].define(version: 2026_07_01_041031) do
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
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_id"], name: "index_scenario_events_on_scenario_id"
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

  create_table "scenarios", force: :cascade do |t|
    t.string "title"
    t.text "introduction"
    t.text "truth"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_scenarios_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "scenario_clues", "scenarios"
  add_foreign_key "scenario_endings", "scenarios"
  add_foreign_key "scenario_events", "scenarios"
  add_foreign_key "scenario_npcs", "scenarios"
  add_foreign_key "scenarios", "users"
end
