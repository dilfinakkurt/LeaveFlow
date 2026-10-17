require "test_helper"

class LeaveBalanceTest < ActiveSupport::TestCase
  setup do
    @manager = create_user(role: "manager")
    @employee = create_user(role: "employee", annual_leave_balance: 15, sick_leave_balance: 10)
  end

  test "pending request does not deduct or alter leave balance" do
    initial_balance = @employee.annual_leave_balance

    req = @employee.leave_requests.create!(
      leave_type: "annual",
      start_date: Date.current.next_week(:monday),
      end_date: Date.current.next_week(:monday) + 3.days, # 4 working days
      reason: "Bekleyen talep bakiye testi"
    )

    @employee.reload
    assert_equal initial_balance, @employee.annual_leave_balance, "Bekleyen talep izin bakiyesini düşürmemelidir."
  end

  test "approved request accurately deducts working days from balance" do
    initial_balance = @employee.annual_leave_balance

    # Monday to Friday = 5 working days
    req = @employee.leave_requests.create!(
      leave_type: "annual",
      start_date: Date.current.next_week(:monday),
      end_date: Date.current.next_week(:monday) + 4.days,
      reason: "Onaylanan talep bakiye testi"
    )

    req.approve!(@manager)

    @employee.reload
    assert_equal initial_balance - 5, @employee.annual_leave_balance, "Onaylanan talep yalnızca iş günleri kadar bakiyeden düşmelidir."
  end

  test "attempting to approve the same request twice does not cause double deduction" do
    initial_balance = @employee.annual_leave_balance

    req = @employee.leave_requests.create!(
      leave_type: "annual",
      start_date: Date.current.next_week(:monday),
      end_date: Date.current.next_week(:monday) + 1.day, # 2 working days
      reason: "Çift onay koruması testi"
    )

    # First approval
    req.approve!(@manager)
    @employee.reload
    assert_equal initial_balance - 2, @employee.annual_leave_balance

    # Second approval attempt must raise error and NOT deduct again
    assert_raises(LeaveRequest::StateTransitionError) do
      req.approve!(@manager)
    end

    @employee.reload
    assert_equal initial_balance - 2, @employee.annual_leave_balance, "İkinci onay girişimi bakiye düşümüne neden olmamalıdır."
  end

  test "rejected request does not deduct or change balance" do
    initial_balance = @employee.annual_leave_balance

    req = @employee.leave_requests.create!(
      leave_type: "annual",
      start_date: Date.current.next_week(:monday),
      end_date: Date.current.next_week(:monday) + 2.days,
      reason: "Reddedilen talep bakiye testi"
    )

    req.reject!(@manager, "Proje yoğunluğu")

    @employee.reload
    assert_equal initial_balance, @employee.annual_leave_balance, "Reddedilen talep bakiyeyi asla etkilememelidir."
  end

  test "unpaid leave approval does not reduce annual or sick balance" do
    annual_init = @employee.annual_leave_balance
    sick_init = @employee.sick_leave_balance

    req = @employee.leave_requests.create!(
      leave_type: "unpaid",
      start_date: Date.current.next_week(:monday),
      end_date: Date.current.next_week(:monday) + 4.days,
      reason: "Ücretsiz izin"
    )

    req.approve!(@manager)

    @employee.reload
    assert_equal annual_init, @employee.annual_leave_balance
    assert_equal sick_init, @employee.sick_leave_balance
  end
end
