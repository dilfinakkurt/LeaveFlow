ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Single worker for reliable, deterministic test execution
    parallelize(workers: 1)

    # Helper method to create standard users in tests
    def create_user(name: "Test User", email: nil, role: "employee", department: "Engineering", annual_leave_balance: 15, sick_leave_balance: 10, password: "password123")
      email ||= "user_#{SecureRandom.hex(4)}@example.com"
      User.create!(
        name: name,
        email: email,
        password: password,
        password_confirmation: password,
        role: role,
        department: department,
        annual_leave_balance: annual_leave_balance,
        sick_leave_balance: sick_leave_balance
      )
    end
  end
end

class ActionDispatch::IntegrationTest
  def log_in_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end
end
