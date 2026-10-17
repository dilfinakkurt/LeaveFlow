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

ActiveRecord::Schema[8.1].define(version: 2026_10_17_000001) do
  create_table "leave_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "leave_type", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.text "reason", null: false
    t.string "status", default: "pending", null: false
    t.integer "decided_by_id"
    t.datetime "decided_at"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["decided_by_id"], name: "index_leave_requests_on_decided_by_id"
    t.index ["start_date", "end_date"], name: "index_leave_requests_on_start_date_and_end_date"
    t.index ["status"], name: "index_leave_requests_on_status"
    t.index ["user_id", "status"], name: "index_leave_requests_on_user_id_and_status"
    t.index ["user_id"], name: "index_leave_requests_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "employee", null: false
    t.string "department", default: "Engineering", null: false
    t.integer "annual_leave_balance", default: 15, null: false
    t.integer "sick_leave_balance", default: 10, null: false
    t.integer "manager_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["manager_id"], name: "index_users_on_manager_id"
  end

  add_foreign_key "leave_requests", "users"
  add_foreign_key "leave_requests", "users", column: "decided_by_id"
  add_foreign_key "users", "users", column: "manager_id"
end
