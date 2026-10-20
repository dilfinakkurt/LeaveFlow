# LeaveReturnSummaryService
# İzin dönüş özetini oluşturan kural tabanlı yapay zeka servisi.
# Gerçek LLM API entegrasyonuna hazır mimari. İlk aşamada kural motoru ile çalışır.
class LeaveReturnSummaryService
  Result = Struct.new(:success?, :summary, :error, keyword_init: true)

  def initialize(user, leave_request)
    @user = user
    @leave_request = leave_request
  end

  def generate!
    unless @leave_request
      return Result.new(success?: false, error: "Geçerli bir onaylanmış izin kaydı bulunamadı.")
    end

    # Güvenlik: Özet yalnızca izin sahibine ait olmalı
    unless @leave_request.user_id == @user.id
      return Result.new(success?: false, error: "Bu izin kaydına erişim yetkiniz bulunmamaktadır.")
    end

    # Yalnızca onaylanmış izinler için özet oluştur
    unless @leave_request.approved?
      return Result.new(success?: false, error: "Yalnızca onaylanmış izin kayıtları için özet oluşturulabilir.")
    end

    # Aynı izin için daha önce özet oluşturulmuşsa güncelle, yoksa yeni oluştur
    events = fetch_relevant_events
    summary = build_or_update_summary(events)

    # İşe dönüş özeti hazır bildirimi oluştur (tekrarlamadan)
    create_return_notification! if summary.persisted?

    Result.new(success?: true, summary: summary)
  rescue => e
    Result.new(success?: false, error: "Özet oluşturulurken bir hata meydana geldi: #{e.message}")
  end

  private

  def fetch_relevant_events
    start_time = @leave_request.start_date.beginning_of_day
    end_time   = @leave_request.end_date.end_of_day

    WorkEvent.for_user(@user).in_range(start_time, end_time).urgent_first
  end

  def build_or_update_summary(events)
    summary = LeaveReturnSummary.find_or_initialize_by(leave_request: @leave_request, user: @user)

    grouped = group_events(events)

    summary.assign_attributes(
      key_developments:      format_section(grouped[:key_developments]),
      assigned_tasks:        format_section(grouped[:assigned_tasks]),
      updated_tasks:         format_section(grouped[:updated_tasks]),
      meeting_announcements: format_section(grouped[:meeting_announcements]),
      priority_items:        format_section(grouped[:priority_items]),
      action_items:          format_section(grouped[:action_items]),
      generated_by:          "ai_rules_engine",
      events_count:          events.size,
      generated_at:          Time.current
    )

    summary.save!
    summary
  end

  def group_events(events)
    result = {
      key_developments:      [],
      assigned_tasks:        [],
      updated_tasks:         [],
      meeting_announcements: [],
      priority_items:        [],
      action_items:          []
    }

    seen_ids = Set.new

    events.each do |event|
      next if seen_ids.include?(event.id) # Aynı olayı iki kez ekleme
      seen_ids.add(event.id)

      entry = format_event_entry(event)

      case event.event_type
      when "task_assigned"
        result[:assigned_tasks] << entry
        result[:action_items] << entry if event.severity.in?(%w[urgent important])
      when "task_status_changed"
        result[:updated_tasks] << entry
        result[:key_developments] << entry if event.severity == "urgent"
      when "task_deadline_changed"
        result[:updated_tasks] << entry
        result[:priority_items] << entry if event.severity.in?(%w[urgent important])
      when "project_update"
        result[:key_developments] << entry
      when "meeting_rescheduled"
        result[:meeting_announcements] << entry
      when "team_announcement"
        result[:meeting_announcements] << entry
        result[:key_developments] << entry if event.severity == "urgent"
      when "pending_action"
        result[:priority_items] << entry
        result[:action_items] << entry
      end
    end

    # Acil olayları öne çıkar
    result.each_value { |list| list.sort_by! { |e| e[:severity_order] } }

    result
  end

  def format_event_entry(event)
    {
      id: event.id,
      icon: event.event_type_icon,
      title: event.title,
      description: event.description,
      date: event.occurred_at.strftime("%d.%m.%Y %H:%M"),
      severity: event.severity_label,
      severity_order: severity_order(event.severity),
      source: event.source_record,
      is_demo: event.is_demo
    }
  end

  def severity_order(severity)
    case severity
    when "urgent"    then 0
    when "important" then 1
    else 2
    end
  end

  def format_section(entries)
    return nil if entries.blank?
    entries.to_json
  end

  def create_return_notification!
    key = "return_summary_lr_#{@leave_request.id}"
    existing = @user.notifications.find_by(notification_key: key)
    return if existing # Zaten bildirim var, tekrarlama

    Notification.create!(
      user: @user,
      notification_type: "return_summary_ready",
      title: "İşe Dönüş Özetiniz Hazır! ✨",
      message: "#{@leave_request.start_date.strftime('%d.%m.%Y')} - #{@leave_request.end_date.strftime('%d.%m.%Y')} tarihleri arasındaki izninize ait işe dönüş özeti oluşturuldu.",
      link_url: "/ai_assistant",
      notification_key: key
    )
  end
end
