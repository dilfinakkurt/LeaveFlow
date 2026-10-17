require "test_helper"

class LeaveRequestTest < ActiveSupport::TestCase
  setup do
    @employee = create_user(role: "employee", annual_leave_balance: 15)
  end

  test "valid leave request creation" do
    req = @employee.leave_requests.build(
      leave_type: "annual",
      start_date: Date.current.next_week(:monday),
      end_date: Date.current.next_week(:monday) + 4.days, # Mon - Fri (5 working days)
      reason: "Yıllık tatil planı"
    )
    assert req.valid?
    assert_equal 5, req.working_days_count
    assert_equal "pending", req.status
  end

  test "invalid date range when start_date is after end_date" do
    req = @employee.leave_requests.build(
      leave_type: "annual",
      start_date: Date.current + 5.days,
      end_date: Date.current + 2.days,
      reason: "Hatalı tarih aralığı"
    )
    assert_not req.valid?
    assert req.errors[:end_date].any?
  end

  test "working days count excludes Saturday and Sunday" do
    # Friday to next Monday: Friday (1), Sat (0), Sun (0), Mon (1) = 2 working days
    friday = Date.current.next_week(:friday)
    monday = friday + 3.days

    req = @employee.leave_requests.build(
      leave_type: "annual",
      start_date: friday,
      end_date: monday,
      reason: "Hafta sonunu kapsayan izin"
    )
    assert_equal 2, req.working_days_count
  end

  test "request spanning only weekend days is invalid" do
    saturday = Date.current.next_week(:saturday)
    sunday = saturday + 1.day

    req = @employee.leave_requests.build(
      leave_type: "annual",
      start_date: saturday,
      end_date: sunday,
      reason: "Sadece hafta sonu"
    )
    assert_not req.valid?
    assert req.errors[:base].any? { |msg| msg.include?("en az 1 iş günü") }
  end

  test "prevents overlapping leave requests for the same employee" do
    monday = Date.current.next_week(:monday)
    wednesday = monday + 2.days

    # First request: Monday to Wednesday (Pending)
    first_req = @employee.leave_requests.create!(
      leave_type: "annual",
      start_date: monday,
      end_date: wednesday,
      reason: "İlk başvuru"
    )
    assert first_req.persisted?

    # Second overlapping request: Tuesday to Thursday
    tuesday = monday + 1.day
    thursday = monday + 3.days
    overlapping = @employee.leave_requests.build(
      leave_type: "annual",
      start_date: tuesday,
      end_date: thursday,
      reason: "Çakışan başvuru"
    )
    assert_not overlapping.valid?
    assert overlapping.errors[:base].any? { |msg| msg.include?("zaten bekleyen veya onaylanmış bir izin talebiniz") }
  end

  test "prevents request creation when annual leave balance is insufficient" do
    low_balance_employee = create_user(annual_leave_balance: 2)
    monday = Date.current.next_week(:monday)
    friday = monday + 4.days # 5 working days needed, only 2 available

    req = low_balance_employee.leave_requests.build(
      leave_type: "annual",
      start_date: monday,
      end_date: friday,
      reason: "Yetersiz bakiye testi"
    )
    assert_not req.valid?
    assert req.errors[:base].any? { |msg| msg.include?("Yetersiz izin bakiyesi") }
  end
end
