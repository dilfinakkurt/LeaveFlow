# NotificationService
# Bildirim oluşturma ve izin durumuna göre otomatik bildirim yönetimi.
class NotificationService
  def initialize(user)
    @user = user
  end

  # İzin durumuna göre bildirimleri kontrol et ve oluştur
  def check_and_notify!
    check_approaching_leaves!
    check_active_leaves!
    check_urgent_events_during_leave!
    check_handover_assignments!
  end

  private

  # İzni yakında başlayacak çalışanlar için bildirim
  def check_approaching_leaves!
    upcoming = @user.leave_requests.approved_requests
                    .where("start_date > ? AND start_date <= ?", Date.current, Date.current + 3.days)

    upcoming.each do |lr|
      key = "leave_approaching_#{lr.id}"
      next if @user.notifications.exists?(notification_key: key)

      days_until = (lr.start_date - Date.current).to_i
      Notification.create!(
        user: @user,
        notification_type: "leave_approaching",
        title: "İzniniz #{days_until} Gün İçinde Başlıyor 🌴",
        message: "#{lr.start_date.strftime('%d.%m.%Y')} - #{lr.end_date.strftime('%d.%m.%Y')} tarihleri arasındaki #{lr.leave_type_label} izniniz yaklaşıyor.",
        link_url: "/leave_requests/#{lr.id}",
        notification_key: key
      )
    end
  end

  # Aktif izindeki çalışanlar için bildirim
  def check_active_leaves!
    active = @user.leave_requests.approved_requests
                  .where("start_date <= ? AND end_date >= ?", Date.current, Date.current)

    active.each do |lr|
      key = "leave_started_#{lr.id}"
      next if @user.notifications.exists?(notification_key: key)

      Notification.create!(
        user: @user,
        notification_type: "leave_started",
        title: "İzin Süreciniz Başladı 🛫",
        message: "#{lr.leave_type_label} izniniz bugün başladı. İzniniz #{lr.end_date.strftime('%d.%m.%Y')} tarihine kadar devam edecek. İyi tatiller!",
        link_url: "/leave_requests/#{lr.id}",
        notification_key: key
      )
    end
  end

  # İzindeyken acil iş hareketleri için bildirim
  def check_urgent_events_during_leave!
    active_leave = @user.current_approved_leave
    return unless active_leave

    urgent_events = WorkEvent.for_user(@user)
                             .in_range(active_leave.start_date.beginning_of_day, Time.current)
                             .where(severity: "urgent")

    urgent_events.each do |event|
      key = "urgent_event_#{event.id}"
      next if @user.notifications.exists?(notification_key: key)

      Notification.create!(
        user: @user,
        notification_type: "urgent_event",
        title: "⚠️ Acil İş Gelişmesi: #{event.title}",
        message: event.description,
        link_url: "/ai_assistant",
        notification_key: key
      )

      # Eğer yedek çalışan varsa, ona da vekaleten bildirim ilet
      if active_leave.backup_user.present?
        backup_key = "backup_urgent_event_#{event.id}_#{active_leave.backup_user_id}"
        unless Notification.exists?(notification_key: backup_key)
          Notification.create!(
            user: active_leave.backup_user,
            notification_type: "urgent_event",
            title: "🤝 [Vekalet Acil] #{event.title}",
            message: "İzindeki ekip arkadaşınız #{active_leave.user.name} adına acil gelişme: #{event.description}",
            link_url: "/ai_assistant",
            notification_key: backup_key
          )
        end
      end
    end
  end

  # Kullanıcının yedek çalışan olarak seçildiği aktif veya yaklaşan izin bildirimleri
  def check_handover_assignments!
    @user.backed_up_leave_requests.approved_requests.where("end_date >= ?", Date.current).each do |lr|
      key = "handover_assign_notice_#{lr.id}_#{@user.id}"
      next if Notification.exists?(notification_key: key)

      note_text = lr.handover_notes.present? ? " Devir Notu: \"#{lr.handover_notes}\"" : ""
      Notification.create!(
        user: @user,
        notification_type: "general",
        title: "🤝 İş Devri: #{lr.user.name} İzni İçin Yedek Çalışansınız",
        message: "#{lr.user.name} (#{lr.start_date.strftime('%d.%m.%Y')} - #{lr.end_date.strftime('%d.%m.%Y')}) tarihleri arasındaki izninde sizi vekil seçti.#{note_text}",
        link_url: "/dashboard",
        notification_key: key
      )
    end
  end
end
