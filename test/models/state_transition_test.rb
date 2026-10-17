require "test_helper"

class StateTransitionTest < ActiveSupport::TestCase
  setup do
    @manager = create_user(role: "manager", name: "Yönetici Ayşe")
    @employee = create_user(role: "employee", name: "Çalışan Ahmet", annual_leave_balance: 15)
    @leave_request = @employee.leave_requests.create!(
      leave_type: "annual",
      start_date: Date.current.next_week(:monday),
      end_date: Date.current.next_week(:monday) + 2.days, # 3 working days
      reason: "Dinlenme izni"
    )
  end

  test "pending request transitions to approved when approved by manager" do
    assert @leave_request.pending?

    @leave_request.approve!(@manager)

    assert @leave_request.approved?
    assert_equal @manager, @leave_request.decided_by
    assert_not_nil @leave_request.decided_at
  end

  test "pending request transitions to rejected with reason when rejected by manager" do
    assert @leave_request.pending?

    @leave_request.reject!(@manager, "Proje teslimatı nedeniyle bu hafta izin verilemiyor.")

    assert @leave_request.rejected?
    assert_equal @manager, @leave_request.decided_by
    assert_not_nil @leave_request.decided_at
    assert_equal "Proje teslimatı nedeniyle bu hafta izin verilemiyor.", @leave_request.rejection_reason
  end

  test "approved request cannot be approved again (idempotency guard)" do
    @leave_request.approve!(@manager)
    assert @leave_request.approved?

    assert_raises(LeaveRequest::StateTransitionError) do
      @leave_request.approve!(@manager)
    end
  end

  test "approved request cannot be transitioned to rejected" do
    @leave_request.approve!(@manager)

    assert_raises(LeaveRequest::StateTransitionError) do
      @leave_request.reject!(@manager, "Geçersiz geçiş")
    end
  end

  test "rejected request cannot be transitioned to approved" do
    @leave_request.reject!(@manager, "Ret edildi")

    assert_raises(LeaveRequest::StateTransitionError) do
      @leave_request.approve!(@manager)
    end
  end

  test "employee cannot approve their own leave request" do
    assert_raises(LeaveRequest::AuthorizationError) do
      @leave_request.approve!(@employee)
    end
  end

  test "user without manager role cannot approve leave request" do
    colleague = create_user(role: "employee", name: "Diğer Çalışan")

    assert_raises(LeaveRequest::AuthorizationError) do
      @leave_request.approve!(colleague)
    end
  end
end
