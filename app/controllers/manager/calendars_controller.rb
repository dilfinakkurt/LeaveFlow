module Manager
  class CalendarsController < ApplicationController
    before_action :require_login

    def show
      # Target month
      @month = params[:month] ? Date.parse(params[:month]) : Date.current.beginning_of_month
      start_of_month = @month.beginning_of_month
      end_of_month = @month.end_of_month

      # Filter by department if requested
      @department = params[:department].presence
      query = LeaveRequest.includes(:user).approved_requests
                          .where("start_date <= ? AND end_date >= ?", end_of_month, start_of_month)

      query = query.joins(:user).where(users: { department: @department }) if @department.present?

      @approved_leaves = query.order(:start_date)
      @departments = User.distinct.pluck(:department).compact
    end
  end
end
