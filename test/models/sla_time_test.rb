require "test_helper"

class SlaTimeTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @manager = create_user(role: "manager")
    @employee = create_user(role: "employee", annual_leave_balance: 15)
    @base_time = Time.zone.parse("2026-10-01 09:00:00")
  end

  test "scenario 1: request is not overdue immediately upon creation" do
    travel_to @base_time do
      request = @employee.leave_requests.create!(
        leave_type: "annual",
        start_date: Date.current.next_week(:monday),
        end_date: Date.current.next_week(:monday) + 2.days,
        reason: "SLA Senaryo 1"
      )

      assert_not request.overdue?, "Yeni oluşturulan talep gecikmiş olmamalıdır."
      assert_not_includes LeaveRequest.overdue, request
    end
  end

  test "scenario 2: request is not overdue at 47 hours" do
    request = nil
    travel_to @base_time do
      request = @employee.leave_requests.create!(
        leave_type: "annual",
        start_date: Date.current.next_week(:monday),
        end_date: Date.current.next_week(:monday) + 2.days,
        reason: "SLA Senaryo 2"
      )
    end

    # Test exactly 47 hours after creation
    travel_to(@base_time + 47.hours) do
      assert_not request.overdue?, "47 saat sonra talep gecikmiş olmamalıdır (SLA 48 saattir)."
      assert_not_includes LeaveRequest.overdue, request
    end
  end

  test "scenario 3: pending request is overdue at exactly 48 hours" do
    request = nil
    travel_to @base_time do
      request = @employee.leave_requests.create!(
        leave_type: "annual",
        start_date: Date.current.next_week(:monday),
        end_date: Date.current.next_week(:monday) + 2.days,
        reason: "SLA Senaryo 3"
      )
    end

    # Test at exactly 48 hours (boundary)
    travel_to(@base_time + 48.hours) do
      assert request.overdue?, "Tam 48 saat dolduğunda hâlâ Pending olan talep gecikmiş sayılmalıdır."
      assert_includes LeaveRequest.overdue, request
    end

    # Test at 50 hours (past boundary)
    travel_to(@base_time + 50.hours) do
      assert request.overdue?, "50 saat sonra bekleyen talep gecikmiş olmalıdır."
      assert_includes LeaveRequest.overdue, request
    end
  end

  test "scenario 4: request approved within SLA is not overdue even after 49 hours" do
    request = nil
    travel_to @base_time do
      request = @employee.leave_requests.create!(
        leave_type: "annual",
        start_date: Date.current.next_week(:monday),
        end_date: Date.current.next_week(:monday) + 2.days,
        reason: "SLA Senaryo 4"
      )
    end

    # Manager approves at 40 hours (within 48h SLA)
    travel_to(@base_time + 40.hours) do
      request.approve!(@manager)
      assert request.approved?
    end

    # Check at 49 hours (past 48h)
    travel_to(@base_time + 49.hours) do
      assert_not request.overdue?, "SLA süresi içinde onaylanan talep 48 saat sonrasında asla gecikmiş gösterilmemelidir."
      assert_not_includes LeaveRequest.overdue, request
    end
  end

  test "scenario 5: request rejected within SLA is not overdue even after 49 hours" do
    request = nil
    travel_to @base_time do
      request = @employee.leave_requests.create!(
        leave_type: "annual",
        start_date: Date.current.next_week(:monday),
        end_date: Date.current.next_week(:monday) + 2.days,
        reason: "SLA Senaryo 5"
      )
    end

    # Manager rejects at 30 hours (within SLA)
    travel_to(@base_time + 30.hours) do
      request.reject!(@manager, "Planlanan bakım çalışması var.")
      assert request.rejected?
    end

    # Check at 49 hours (past 48h)
    travel_to(@base_time + 49.hours) do
      assert_not request.overdue?, "SLA süresi içinde reddedilen talep 48 saat sonrasında asla gecikmiş gösterilmemelidir."
      assert_not_includes LeaveRequest.overdue, request
    end
  end
end
