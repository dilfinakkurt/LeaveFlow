# TeamAnalyticsService
# Yöneticiler için Ekip Kapsama, Kapasite ve İzin Dönüşü İş Yükü Risk Analitiği.
class TeamAnalyticsService
  def initialize(manager, department = nil)
    @manager = manager
    @department = department.presence || manager.department
  end

  def analyze
    users_scope = User.where(role: "employee")
    users_scope = users_scope.where(department: @department) if @department.present?

    total_employees = users_scope.count
    return empty_analytics if total_employees == 0

    today = Date.current

    # 1. Şu anda aktif izinde olanlar
    currently_on_leave = LeaveRequest.approved_requests
                                     .joins(:user)
                                     .merge(users_scope)
                                     .where("start_date <= ? AND end_date >= ?", today, today)

    on_leave_count = currently_on_leave.count
    active_working_count = total_employees - on_leave_count
    capacity_percentage = [(active_working_count.to_f / total_employees * 100).round, 0].max

    # 2. Önümüzdeki 7 gün içinde izne çıkacak olanlar
    upcoming_leaves = LeaveRequest.approved_requests
                                  .joins(:user)
                                  .merge(users_scope)
                                  .where("start_date > ? AND start_date <= ?", today, today + 7.days)
                                  .order(start_date: :asc)

    # 3. İşe yeni dönen veya dönmek üzere olan çalışanların birikmiş iş yükü analizi
    return_surge_analysis = build_return_surge_analysis(users_scope)

    # 4. Proje ve Teslim Riski Analizi (İzindeyken teslim tarihi olan veya acil işi olanlar)
    project_delay_risks = build_project_delay_risks(currently_on_leave)

    # 5. Yedek Çalışan (Handover) Kapsama Oranı
    active_and_upcoming = LeaveRequest.approved_requests
                                      .joins(:user)
                                      .merge(users_scope)
                                      .where("end_date >= ?", today)

    with_backup_count = active_and_upcoming.where.not(backup_user_id: nil).count
    backup_coverage_rate = active_and_upcoming.any? ? (with_backup_count.to_f / active_and_upcoming.count * 100).round : 100

    {
      department: @department,
      total_employees: total_employees,
      active_working_count: active_working_count,
      on_leave_count: on_leave_count,
      capacity_percentage: capacity_percentage,
      capacity_status: capacity_status(capacity_percentage),
      currently_on_leave: currently_on_leave,
      upcoming_leaves: upcoming_leaves,
      return_surge_analysis: return_surge_analysis,
      project_delay_risks: project_delay_risks,
      backup_coverage_rate: backup_coverage_rate,
      unbacked_leaves: active_and_upcoming.where(backup_user_id: nil)
    }
  end

  private

  def capacity_status(pct)
    if pct >= 75
      { label: "Güvenli Kapasite", color: "#10b981", badge_class: "badge-normal" }
    elsif pct >= 50
      { label: "Orta Seviye Kapasite", color: "#f59e0b", badge_class: "badge-important" }
    else
      { label: "Kritik Kapasite Riski", color: "#ef4444", badge_class: "badge-urgent" }
    end
  end

  def build_return_surge_analysis(users_scope)
    today = Date.current
    # Son 7 gün içinde izni bitenler veya bugün bitenler
    recent_returns = LeaveRequest.approved_requests
                                 .joins(:user)
                                 .merge(users_scope)
                                 .where("end_date <= ? AND end_date >= ?", today, today - 7.days)

    recent_returns.map do |lr|
      events = WorkEvent.for_user(lr.user).in_range(lr.start_date.beginning_of_day, lr.end_date.end_of_day)
      urgent_count = events.where(severity: "urgent").count
      total_count = events.count

      surge_level = if urgent_count > 0 || total_count >= 4
        { label: "Yüksek Birikim", color: "#ef4444", badge_class: "badge-urgent" }
      elsif total_count >= 1
        { label: "Orta Düzey", color: "#f59e0b", badge_class: "badge-important" }
      else
        { label: "Düşük / Sakin", color: "#10b981", badge_class: "badge-normal" }
      end

      {
        user: lr.user,
        leave_request: lr,
        total_events: total_count,
        urgent_events: urgent_count,
        surge_level: surge_level,
        has_summary: lr.leave_return_summary.present?
      }
    end
  end

  def build_project_delay_risks(active_leaves)
    risks = []

    active_leaves.each do |lr|
      urgent_or_deadline_events = WorkEvent.for_user(lr.user)
                                           .in_range(lr.start_date.beginning_of_day, lr.end_date.end_of_day)
                                           .where(event_type: %w[task_assigned task_deadline_changed pending_action])

      urgent_or_deadline_events.each do |event|
        risks << {
          user: lr.user,
          leave_request: lr,
          event: event,
          backup_user: lr.backup_user,
          action_needed: lr.backup_user ? "#{lr.backup_user.name} vekaleten devralmalı" : "Acil yedek çalışan atanmalı!"
        }
      end
    end

    risks
  end

  def empty_analytics
    {
      department: @department,
      total_employees: 0,
      active_working_count: 0,
      on_leave_count: 0,
      capacity_percentage: 100,
      capacity_status: { label: "Veri Yok", color: "#64748b", badge_class: "badge-normal" },
      currently_on_leave: LeaveRequest.none,
      upcoming_leaves: LeaveRequest.none,
      return_surge_analysis: [],
      project_delay_risks: [],
      backup_coverage_rate: 100,
      unbacked_leaves: LeaveRequest.none
    }
  end
end
