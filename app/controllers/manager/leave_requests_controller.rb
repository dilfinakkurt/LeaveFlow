module Manager
  class LeaveRequestsController < ApplicationController
    before_action :require_manager
    before_action :set_leave_request, only: [:show, :approve, :reject]

    def index
      @filter = params[:filter].presence || "pending"

      base_scope = LeaveRequest.includes(:user, :decided_by)

      @all_count = LeaveRequest.count
      @pending_count = LeaveRequest.pending_requests.count
      @overdue_count = LeaveRequest.overdue.count
      @approved_count = LeaveRequest.approved_requests.count
      @rejected_count = LeaveRequest.rejected_requests.count

      @leave_requests = case @filter
      when "pending"
        base_scope.pending_requests.order(created_at: :asc)
      when "overdue"
        base_scope.overdue.order(created_at: :asc)
      when "approved"
        base_scope.approved_requests.order(decided_at: :desc)
      when "rejected"
        base_scope.rejected_requests.order(decided_at: :desc)
      else
        base_scope.ordered_by_urgency
      end
    end

    def show
      @conflicting_requests = @leave_request.conflicting_team_requests
    end

    def approve
      begin
        @leave_request.approve!(current_user)
        flash[:notice] = "#{@leave_request.user.name} çalışanının izin talebi onaylandı. İzin bakiyesi başarıyla düşürüldü."
      rescue LeaveRequest::AuthorizationError, LeaveRequest::StateTransitionError, LeaveRequest::InsufficientBalanceError => e
        flash[:alert] = "Onay işlemi başarısız: #{e.message}"
      rescue => e
        flash[:alert] = "Beklenmeyen bir hata oluştu: #{e.message}"
      end
      redirect_back fallback_location: manager_leave_requests_path
    end

    def reject
      reason = params[:rejection_reason].to_s.strip
      if reason.blank?
        flash[:alert] = "Lütfen bir ret gerekçesi belirtiniz."
        redirect_back fallback_location: manager_leave_request_path(@leave_request)
        return
      end

      begin
        @leave_request.reject!(current_user, reason)
        flash[:notice] = "#{@leave_request.user.name} çalışanının izin talebi reddedildi."
      rescue LeaveRequest::AuthorizationError, LeaveRequest::StateTransitionError => e
        flash[:alert] = "Ret işlemi başarısız: #{e.message}"
      rescue => e
        flash[:alert] = "Beklenmeyen bir hata oluştu: #{e.message}"
      end
      redirect_back fallback_location: manager_leave_requests_path
    end

    private

    def set_leave_request
      @leave_request = LeaveRequest.find(params[:id])
    end
  end
end
