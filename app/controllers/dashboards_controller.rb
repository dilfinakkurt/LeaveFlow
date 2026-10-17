class DashboardsController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    @recent_requests = @user.leave_requests.order(created_at: :desc).limit(5)
    @pending_count = @user.leave_requests.pending_requests.count
    @approved_count = @user.leave_requests.approved_requests.count
    @rejected_count = @user.leave_requests.rejected_requests.count

    if @user.manager?
      @manager_pending_count = LeaveRequest.pending_requests.count
      @manager_overdue_count = LeaveRequest.overdue.count
    end
  end
end
