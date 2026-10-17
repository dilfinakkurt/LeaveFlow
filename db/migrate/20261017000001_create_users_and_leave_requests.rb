class CreateUsersAndLeaveRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "employee" # employee, manager
      t.string :department, null: false, default: "Engineering"
      t.integer :annual_leave_balance, null: false, default: 15
      t.integer :sick_leave_balance, null: false, default: 10
      t.references :manager, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :users, :email, unique: true

    create_table :leave_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :leave_type, null: false # annual, sick, unpaid
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.text :reason, null: false
      t.string :status, null: false, default: "pending" # pending, approved, rejected
      t.references :decided_by, foreign_key: { to_table: :users }
      t.datetime :decided_at
      t.text :rejection_reason

      t.timestamps
    end

    add_index :leave_requests, :status
    add_index :leave_requests, [:user_id, :status]
    add_index :leave_requests, [:start_date, :end_date]
  end
end
