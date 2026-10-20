class WorkEvent < ApplicationRecord
  # Event Types
  EVENT_TYPES = %w[
    task_assigned
    task_status_changed
    task_deadline_changed
    project_update
    meeting_rescheduled
    team_announcement
    pending_action
  ].freeze

  SEVERITIES = %w[urgent important normal].freeze

  # Associations
  belongs_to :user, optional: true # Optional: null means team/dept wide

  # Validations
  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true
  validates :occurred_at, presence: true
  validates :severity, presence: true, inclusion: { in: SEVERITIES }

  # Scopes
  scope :for_user, ->(target_user) {
    if target_user.department.present?
      where(user_id: target_user.id).or(where(user_id: nil, department: [target_user.department, nil]))
    else
      where(user_id: target_user.id).or(where(user_id: nil, department: nil))
    end
  }

  scope :in_range, ->(start_time, end_time) {
    where(occurred_at: start_time..end_time)
  }

  scope :chronological, -> { order(occurred_at: :asc) }
  scope :recent_first, -> { order(occurred_at: :desc) }
  scope :urgent_first, -> {
    order(
      Arel.sql("CASE severity WHEN 'urgent' THEN 0 WHEN 'important' THEN 1 ELSE 2 END"),
      occurred_at: :desc
    )
  }

  # Helper Labels
  def event_type_label
    case event_type
    when "task_assigned"          then "Yeni Görev Ataması"
    when "task_status_changed"    then "Görev Durumu Değişikliği"
    when "task_deadline_changed"  then "Teslim Tarihi Değişikliği"
    when "project_update"         then "Proje Gelişmesi"
    when "meeting_rescheduled"    then "Toplantı Değişikliği"
    when "team_announcement"      then "Ekip Duyurusu"
    when "pending_action"         then "Bekleyen Öncelikli İş"
    else event_type.humanize
    end
  end

  def severity_label
    case severity
    when "urgent"    then "Acil"
    when "important" then "Önemli"
    when "normal"    then "Normal"
    else severity.humanize
    end
  end

  def severity_badge_class
    case severity
    when "urgent"    then "badge-urgent"
    when "important" then "badge-important"
    when "normal"    then "badge-normal"
    else "badge-normal"
    end
  end

  def event_type_icon
    case event_type
    when "task_assigned"         then "📋"
    when "task_status_changed"   then "🔄"
    when "task_deadline_changed" then "⏳"
    when "project_update"        then "🚀"
    when "meeting_rescheduled"   then "📅"
    when "team_announcement"     then "📢"
    when "pending_action"        then "⚡"
    else "📌"
    end
  end
end
