require "test_helper"

class LeaveRequestFlowTest < ActionDispatch::IntegrationTest
  setup do
    @manager = create_user(
      name: "Ayşe Yönetici",
      email: "ayse@company.com",
      role: "manager",
      department: "Engineering"
    )

    @employee_1 = create_user(
      name: "Ahmet Çalışan",
      email: "ahmet@company.com",
      role: "employee",
      department: "Engineering",
      annual_leave_balance: 15
    )

    @employee_2 = create_user(
      name: "Mehmet Çalışan",
      email: "mehmet@company.com",
      role: "employee",
      department: "Engineering",
      annual_leave_balance: 15
    )
  end

  test "complete end-to-end flow: employee applies, manager approves, balance is deducted" do
    # 1. Ahmet logs in
    log_in_as(@employee_1)
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
    assert_select "h1", text: /Hoş Geldiniz, Ahmet Çalışan/

    # 2. Ahmet submits a 3-working-day leave request
    next_monday = Date.current.next_week(:monday)
    next_wednesday = next_monday + 2.days

    get new_leave_request_path
    assert_response :success

    assert_difference("LeaveRequest.count", 1) do
      post leave_requests_path, params: {
        leave_request: {
          leave_type: "annual",
          start_date: next_monday,
          end_date: next_wednesday,
          reason: "Kişisel tatil başvurusu"
        }
      }
    end

    created_request = LeaveRequest.last
    assert_redirected_to leave_request_path(created_request)
    follow_redirect!
    assert_response :success
    assert_equal "pending", created_request.status

    # 3. Verify balance is NOT deducted yet (still 15)
    @employee_1.reload
    assert_equal 15, @employee_1.annual_leave_balance

    # 4. Ahmet logs out
    delete logout_path
    assert_redirected_to login_path

    # 5. Manager Ayşe logs in
    log_in_as(@manager)
    assert_redirected_to manager_leave_requests_path
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Ahmet Çalışan"

    # 6. Manager approves the request
    patch approve_manager_leave_request_path(created_request)
    assert_redirected_to manager_leave_requests_path
    follow_redirect!
    assert_includes response.body, "izin talebi onaylandı"

    created_request.reload
    assert_equal "approved", created_request.status
    assert_equal @manager.id, created_request.decided_by_id

    # 7. Verify balance is now correctly deducted (15 - 3 = 12)
    @employee_1.reload
    assert_equal 12, @employee_1.annual_leave_balance

    # 8. Manager logs out
    delete logout_path

    # 9. Ahmet logs in and checks his status and balance
    log_in_as(@employee_1)
    get leave_requests_path
    assert_response :success
    assert_includes response.body, "Onaylandı"
    assert_includes response.body, "12 gün"
  end

  test "employee cannot access manager approval portal" do
    log_in_as(@employee_1)
    get manager_leave_requests_path

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_includes response.body, "yönetici yetkisine sahip olmalısınız"
  end

  test "employee cannot view another employee's private leave request" do
    # Create request for employee 2
    req_2 = @employee_2.leave_requests.create!(
      leave_type: "annual",
      start_date: Date.current.next_week(:monday),
      end_date: Date.current.next_week(:monday) + 1.day,
      reason: "Mehmet'in özel izni"
    )

    # Employee 1 logs in and tries to access Employee 2's request
    log_in_as(@employee_1)
    get leave_request_path(req_2)

    assert_redirected_to leave_requests_path
    follow_redirect!
    assert_includes response.body, "Yetkiniz olmayan bir izin talebine erişemezsiniz"
  end

  test "employee cannot approve their own request via HTTP request" do
    req = @employee_1.leave_requests.create!(
      leave_type: "annual",
      start_date: Date.current.next_week(:monday),
      end_date: Date.current.next_week(:monday) + 1.day,
      reason: "Kendi iznimi onaylama testi"
    )

    log_in_as(@employee_1)
    # Attempting to call manager approve endpoint directly as employee
    patch approve_manager_leave_request_path(req)

    assert_redirected_to dashboard_path
    req.reload
    assert_equal "pending", req.status, "Yetkisiz istek durumu değiştirmemelidir."
  end
end
