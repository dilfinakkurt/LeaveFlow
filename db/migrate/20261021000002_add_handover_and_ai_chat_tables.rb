class AddHandoverAndAiChatTables < ActiveRecord::Migration[8.1]
  def change
    # 1. Add Handover / Backup Colleague to Leave Requests
    add_reference :leave_requests, :backup_user, foreign_key: { to_table: :users }, null: true
    add_column :leave_requests, :handover_notes, :text

    # 2. AI Chat Messages Table for Interactive Q&A
    create_table :ai_chat_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :leave_request, null: true, foreign_key: true
      t.string :role, null: false # 'user' or 'assistant'
      t.text :content, null: false

      t.timestamps
    end

    add_index :ai_chat_messages, [:user_id, :created_at]
    add_index :ai_chat_messages, [:leave_request_id, :created_at]
  end
end
