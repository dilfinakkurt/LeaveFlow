class AiAssistantController < ApplicationController
  before_action :require_login

  def show
    @user = current_user

    # Bildirimleri kontrol et ve oluştur
    NotificationService.new(@user).check_and_notify!

    # Kullanıcının aktif veya yaklaşan onaylı izinleri
    @active_leave = @user.current_approved_leave
    @upcoming_leaves = @user.leave_requests.approved_requests
                            .where("start_date > ?", Date.current)
                            .order(start_date: :asc)

    # Son biten izinler (son 30 gün)
    @recent_past_leaves = @user.leave_requests.approved_requests
                               .where("end_date < ? AND end_date >= ?", Date.current, Date.current - 30.days)
                               .order(end_date: :desc)

    # Hedef izin: aktif izin, son biten veya yaklaşan izin
    @target_leave = @active_leave || @recent_past_leaves.first || @upcoming_leaves.first

    if @target_leave
      start_time = @target_leave.start_date.beginning_of_day
      end_time   = @target_leave.end_date.end_of_day
      @events = WorkEvent.for_user(@user).in_range(start_time, end_time).urgent_first
      @events_count = @events.count
      @urgent_events = @events.where(severity: "urgent")
      @important_events = @events.where(severity: "important")
      @summary = LeaveReturnSummary.find_by(leave_request: @target_leave, user: @user)
    else
      @events = WorkEvent.none
      @events_count = 0
      @urgent_events = WorkEvent.none
      @important_events = WorkEvent.none
      @summary = nil
    end

    # Kullanıcı bildirimleri
    @notifications = @user.notifications.recent_first.limit(20)
    @unread_count = @user.unread_notifications_count

    # AI Sohbet Geçmişi
    @chat_messages = @user.ai_chat_messages.chronological.limit(50)
  end

  def chat
    question = params[:question].to_s.strip
    target_leave = current_user.leave_requests.approved_requests.find_by(id: params[:leave_request_id]) ||
                   current_user.current_approved_leave ||
                   current_user.leave_requests.approved_requests.order(end_date: :desc).first

    if question.present?
      AiChatService.new(current_user, target_leave).answer(question)
    end

    redirect_to ai_assistant_path(anchor: "chat-box")
  end

  def clear_chat
    current_user.ai_chat_messages.destroy_all
    flash[:notice] = "Sohbet geçmişi temizlendi."
    redirect_to ai_assistant_path(anchor: "chat-box")
  end

  def generate_summary
    leave_request = current_user.leave_requests.approved_requests.find_by(id: params[:leave_request_id])

    unless leave_request
      flash[:alert] = "Geçerli bir onaylanmış izin kaydı bulunamadı."
      redirect_to ai_assistant_path and return
    end

    result = LeaveReturnSummaryService.new(current_user, leave_request).generate!

    if result.success?
      flash[:notice] = "İşe dönüş özetiniz başarıyla oluşturuldu! ✨"
    else
      flash[:alert] = result.error
    end

    redirect_to ai_assistant_path
  end

  def mark_notification_read
    notification = current_user.notifications.find_by(id: params[:id])

    if notification
      notification.mark_as_read!
      respond_to do |format|
        format.html { redirect_to ai_assistant_path }
        format.json { render json: { success: true, unread_count: current_user.unread_notifications_count } }
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = "Bildirim bulunamadı."
          redirect_to ai_assistant_path
        end
        format.json { render json: { success: false }, status: :not_found }
      end
    end
  end

  def mark_all_notifications_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html do
        flash[:notice] = "Tüm bildirimler okundu olarak işaretlendi."
        redirect_to ai_assistant_path
      end
      format.json { render json: { success: true, unread_count: 0 } }
    end
  end
end
