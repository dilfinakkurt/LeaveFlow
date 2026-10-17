class LeaveRequestsController < ApplicationController
  before_action :require_login
  before_action :set_leave_request, only: [:show]

  def index
    # Server-side authorization: An employee can ONLY see their own leave requests!
    @leave_requests = current_user.leave_requests.order(created_at: :desc)
    @pending_count = @leave_requests.pending_requests.count
    @approved_count = @leave_requests.approved_requests.count
    @rejected_count = @leave_requests.rejected_requests.count
  end

  def show
    @conflicting_requests = @leave_request.conflicting_team_requests
  end

  def new
    @leave_request = current_user.leave_requests.build(
      leave_type: "annual",
      start_date: Date.current + 1.day,
      end_date: Date.current + 3.days
    )
    load_conflicts_for_preview
  end

  def check_conflicts
    start_date = Date.parse(params[:start_date]) rescue nil
    end_date = Date.parse(params[:end_date]) rescue nil

    conflicts = if start_date && end_date && start_date <= end_date
      LeaveRequest.team_conflicts_for(current_user, start_date, end_date).map do |req|
        {
          id: req.id,
          user_name: req.user.name,
          department: req.user.department,
          start_date: req.start_date.strftime("%d.%m.%Y"),
          end_date: req.end_date.strftime("%d.%m.%Y"),
          leave_type: req.leave_type_label
        }
      end
    else
      []
    end

    render json: { conflicts: conflicts }
  end

  def create
    @leave_request = current_user.leave_requests.build(leave_request_params)

    if @leave_request.save
      conflicts = @leave_request.conflicting_team_requests
      if conflicts.any?
        names = conflicts.map { |c| c.user.name }.uniq.join(", ")
        flash[:notice] = "İzin talebiniz başarıyla oluşturuldu. ℹ️ Ekip Bilgilendirmesi: Belirttiğiniz tarihlerde ekip arkadaşınız (#{names}) da onaylı izindedir. Bu durum yöneticinizin onayına sunulacaktır."
      else
        flash[:notice] = "İzin talebiniz başarıyla oluşturuldu ve yönetici onayına iletildi."
      end
      redirect_to leave_request_path(@leave_request)
    else
      load_conflicts_for_preview
      flash.now[:alert] = "Lütfen formdaki hataları kontrol ediniz."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_leave_request
    # An employee can only view their own requests, unless manager
    if current_user.manager?
      @leave_request = LeaveRequest.find(params[:id])
    else
      @leave_request = current_user.leave_requests.find_by(id: params[:id])
      unless @leave_request
        flash[:alert] = "Yetkiniz olmayan bir izin talebine erişemezsiniz."
        redirect_to leave_requests_path
      end
    end
  end

  def leave_request_params
    params.require(:leave_request).permit(:leave_type, :start_date, :end_date, :reason)
  end

  def load_conflicts_for_preview
    if @leave_request.start_date && @leave_request.end_date && @leave_request.start_date <= @leave_request.end_date
      @team_conflicts = LeaveRequest.team_conflicts_for(current_user, @leave_request.start_date, @leave_request.end_date)
    else
      @team_conflicts = LeaveRequest.none
    end
  end
end
