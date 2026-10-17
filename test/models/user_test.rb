require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user attributes" do
    user = create_user(name: "Ali Veli", email: "ali@example.com")
    assert user.valid?
    assert_equal "ali@example.com", user.email
    assert_equal 15, user.annual_leave_balance
    assert_equal 10, user.sick_leave_balance
  end

  test "email is normalized to lowercase and trimmed" do
    user = create_user(email: "  CAN@Example.COM ")
    assert_equal "can@example.com", user.email
  end

  test "email must be unique (case-insensitive)" do
    create_user(email: "unique@example.com")
    duplicate = User.new(
      name: "Duplicate",
      email: "UNIQUE@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "role helper methods" do
    employee = create_user(role: "employee")
    manager = create_user(role: "manager")

    assert employee.employee?
    assert_not employee.manager?

    assert manager.manager?
    assert_not manager.employee?
  end

  test "balance deduction handles annual and sick leave correctly" do
    user = create_user(annual_leave_balance: 10, sick_leave_balance: 5)

    user.deduct_balance!("annual", 3)
    assert_equal 7, user.annual_leave_balance

    user.deduct_balance!("sick", 2)
    assert_equal 3, user.sick_leave_balance

    user.deduct_balance!("unpaid", 5) # Unpaid doesn't change balances
    assert_equal 7, user.annual_leave_balance
  end

  test "balance deduction raises error if insufficient balance" do
    user = create_user(annual_leave_balance: 2)

    assert_raises(ArgumentError) do
      user.deduct_balance!("annual", 3)
    end
  end
end
