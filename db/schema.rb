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

ActiveRecord::Schema[8.1].define(version: 2026_10_21_000002) do
  create_table "ai_chat_messages", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "leave_request_id"
    t.string "role", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["leave_request_id", "created_at"], name: "index_ai_chat_messages_on_leave_request_id_and_created_at"
    t.index ["leave_request_id"], name: "index_ai_chat_messages_on_leave_request_id"
    t.index ["user_id", "created_at"], name: "index_ai_chat_messages_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_ai_chat_messages_on_user_id"
  end

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
    t.integer "backup_user_id"
    t.text "handover_notes"
    t.index ["backup_user_id"], name: "index_leave_requests_on_backup_user_id"
    t.index ["decided_by_id"], name: "index_leave_requests_on_decided_by_id"
    t.index ["start_date", "end_date"], name: "index_leave_requests_on_start_date_and_end_date"
    t.index ["status"], name: "index_leave_requests_on_status"
    t.index ["user_id", "status"], name: "index_leave_requests_on_user_id_and_status"
    t.index ["user_id"], name: "index_leave_requests_on_user_id"
  end

  create_table "leave_return_summaries", force: :cascade do |t|
    t.integer "leave_request_id", null: false
    t.integer "user_id", null: false
    t.text "key_developments"
    t.text "assigned_tasks"
    t.text "updated_tasks"
    t.text "meeting_announcements"
    t.text "priority_items"
    t.text "action_items"
    t.string "generated_by", default: "ai_rules_engine", null: false
    t.integer "events_count", default: 0, null: false
    t.datetime "generated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["leave_request_id"], name: "index_leave_return_summaries_on_leave_request_id", unique: true
    t.index ["user_id"], name: "index_leave_return_summaries_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "notification_type", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.datetime "read_at"
    t.string "link_url"
    t.string "notification_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "notification_key"], name: "index_notifications_on_user_id_and_notification_key"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
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

  create_table "work_events", force: :cascade do |t|
    t.integer "user_id"
    t.string "department"
    t.string "event_type", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "occurred_at", null: false
    t.string "source_record"
    t.string "severity", default: "normal", null: false
    t.boolean "is_demo", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department", "occurred_at"], name: "index_work_events_on_department_and_occurred_at"
    t.index ["event_type"], name: "index_work_events_on_event_type"
    t.index ["occurred_at"], name: "index_work_events_on_occurred_at"
    t.index ["severity"], name: "index_work_events_on_severity"
    t.index ["user_id", "occurred_at"], name: "index_work_events_on_user_id_and_occurred_at"
    t.index ["user_id"], name: "index_work_events_on_user_id"
  end

  add_foreign_key "ai_chat_messages", "leave_requests"
  add_foreign_key "ai_chat_messages", "users"
  add_foreign_key "leave_requests", "users"
  add_foreign_key "leave_requests", "users", column: "backup_user_id"
  add_foreign_key "leave_requests", "users", column: "decided_by_id"
  add_foreign_key "leave_return_summaries", "leave_requests"
  add_foreign_key "leave_return_summaries", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "users", "users", column: "manager_id"
  add_foreign_key "work_events", "users"
end
