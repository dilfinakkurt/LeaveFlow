class Notification < ApplicationRecord
  NOTIFICATION_TYPES = %w[
    leave_approaching
    leave_started
    urgent_event
    return_summary_ready
    general
  ].freeze

  # Associations
  belongs_to :user

  # Validations
  validates :notification_type, presence: true, inclusion: { in: NOTIFICATION_TYPES }
  validates :title, presence: true
  validates :message, presence: true

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent_first, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def type_icon
    case notification_type
    when "leave_approaching"   then "🌴"
    when "leave_started"       then "🛫"
    when "urgent_event"        then "⚠️"
    when "return_summary_ready" then "✨"
    else "🔔"
    end
  end
end
