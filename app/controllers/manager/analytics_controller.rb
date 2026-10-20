module Manager
  class AnalyticsController < ApplicationController
    before_action :require_manager

    def show
      @departments = User.where(role: "employee").distinct.pluck(:department).compact
      @selected_department = params[:department].presence || current_user.department

      service = TeamAnalyticsService.new(current_user, @selected_department)
      @analytics = service.analyze
    end
  end
end
