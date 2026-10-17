require "test_helper"

class TeamConflictTest < ActiveSupport::TestCase
  setup do
    @manager = create_user(role: "manager", department: "Engineering")
    @engineer_1 = create_user(name: "Mühendis Ahmet", department: "Engineering")
    @engineer_2 = create_user(name: "Mühendis Mehmet", department: "Engineering")
    @sales_rep = create_user(name: "Satışçı Selin", department: "Sales")

    @next_monday = Date.current.next_week(:monday)
    @next_friday = @next_monday + 4.days

    # Ahmet has an approved leave from next Monday to Friday
    @ahmet_leave = @engineer_1.leave_requests.create!(
      leave_type: "annual",
      start_date: @next_monday,
      end_date: @next_friday,
      reason: "Yıllık izin planı",
      status: "approved",
      decided_by: @manager,
      decided_at: 1.day.ago
    )
  end

  test "detects approved leave conflict for colleague in the same department" do
    # Mehmet wants leave on Wednesday to Friday (overlaps with Ahmet)
    wednesday = @next_monday + 2.days
    friday = @next_friday

    conflicts = LeaveRequest.team_conflicts_for(@engineer_2, wednesday, friday)

    assert_equal 1, conflicts.count
    assert_includes conflicts, @ahmet_leave
  end

  test "does not detect conflict if colleague is in a different department" do
    # Selin (Sales) requests leave on the exact same dates as Ahmet (Engineering)
    conflicts = LeaveRequest.team_conflicts_for(@sales_rep, @next_monday, @next_friday)

    assert_empty conflicts, "Farklı departmandaki çalışanların izinleri ekip çakışması olarak değerlendirilmemelidir."
  end

  test "does not flag pending requests of teammates as approved conflicts" do
    # Engineer 2 has a pending request
    tuesday = @next_monday + 1.day
    pending_leave = @engineer_2.leave_requests.create!(
      leave_type: "annual",
      start_date: tuesday,
      end_date: tuesday + 1.day,
      reason: "Bekleyen talep"
    )

    engineer_3 = create_user(name: "Mühendis Can", department: "Engineering")
    conflicts = LeaveRequest.team_conflicts_for(engineer_3, tuesday, tuesday + 1.day)

    # Only Ahmet's approved leave is a conflict, Mehmet's pending leave is not
    assert_equal 1, conflicts.count
    assert_includes conflicts, @ahmet_leave
    assert_not_includes conflicts, pending_leave
  end

  test "does not flag leaves outside the date range" do
    # Mehmet requests leave two weeks later
    future_start = @next_monday + 14.days
    future_end = future_start + 4.days

    conflicts = LeaveRequest.team_conflicts_for(@engineer_2, future_start, future_end)

    assert_empty conflicts, "Tarihleri kesişmeyen izinler çakışma olarak raporlanmamalıdır."
  end
end
