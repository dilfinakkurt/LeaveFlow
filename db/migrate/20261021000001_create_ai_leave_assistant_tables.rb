class CreateAiLeaveAssistantTables < ActiveRecord::Migration[8.1]
  def change
    # 1. Work Events Table
    create_table :work_events do |t|
      t.references :user, foreign_key: true, null: true, index: true
      t.string :department
      t.string :event_type, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.datetime :occurred_at, null: false
      t.string :source_record
      t.string :severity, null: false, default: "normal" # urgent, important, normal
      t.boolean :is_demo, null: false, default: true

      t.timestamps
    end

    add_index :work_events, [:user_id, :occurred_at]
    add_index :work_events, [:department, :occurred_at]
    add_index :work_events, :occurred_at
    add_index :work_events, :event_type
    add_index :work_events, :severity

    # 2. Leave Return Summaries Table
    create_table :leave_return_summaries do |t|
      t.references :leave_request, null: false, foreign_key: true, index: { unique: true }
      t.references :user, null: false, foreign_key: true, index: true
      t.text :key_developments
      t.text :assigned_tasks
      t.text :updated_tasks
      t.text :meeting_announcements
      t.text :priority_items
      t.text :action_items
      t.string :generated_by, null: false, default: "ai_rules_engine"
      t.integer :events_count, null: false, default: 0
      t.datetime :generated_at, null: false

      t.timestamps
    end

    # 3. Employee Notifications Table
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :message, null: false
      t.datetime :read_at
      t.string :link_url
      t.string :notification_key

      t.timestamps
    end

    add_index :notifications, [:user_id, :read_at]
    add_index :notifications, [:user_id, :notification_key]
  end
end
