class LeaveRequest < ApplicationRecord
  # Custom error classes for clean business rule exceptions
  class StateTransitionError < StandardError; end
  class AuthorizationError < StandardError; end
  class InsufficientBalanceError < StandardError; end

  # Constants
  STATUSES = %w[pending approved rejected].freeze
  LEAVE_TYPES = %w[annual sick unpaid].freeze
  SLA_HOURS = 48
  SLA_LIMIT = 48.hours

  # Associations
  belongs_to :user
  belongs_to :decided_by, class_name: "User", optional: true

  # Validations
  validates :leave_type, presence: true, inclusion: { in: LEAVE_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :reason, presence: true, length: { minimum: 3, maximum: 1000 }
  validate :validate_dates_order
  validate :validate_no_overlapping_requests_for_user, on: :create
  validate :validate_sufficient_balance, on: :create

  # Scopes
  scope :pending_requests, -> { where(status: "pending") }
  scope :approved_requests, -> { where(status: "approved") }
  scope :rejected_requests, -> { where(status: "rejected") }
  scope :overdue, -> { pending_requests.where("leave_requests.created_at <= ?", SLA_LIMIT.ago) }
  scope :ordered_by_urgency, -> {
    # Pending first, then overdue first, then newest
    order(
      Arel.sql("CASE status WHEN 'pending' THEN 0 WHEN 'approved' THEN 1 ELSE 2 END"),
      Arel.sql("CASE WHEN status = 'pending' AND created_at <= '#{SLA_LIMIT.ago.to_fs(:db)}' THEN 0 ELSE 1 END"),
      created_at: :desc
    )
  }

  # Human readable translations
  def leave_type_label
    case leave_type
    when "annual" then "Yıllık İzin"
    when "sick" then "Hastalık İzni"
    when "unpaid" then "Ücretsiz İzin"
    else leave_type.titleize
    end
  end

  def status_label
    case status
    when "pending" then "Beklemede"
    when "approved" then "Onaylandı"
    when "rejected" then "Reddedildi"
    else status.titleize
    end
  end

  # Working days calculation (excluding Saturday and Sunday)
  # Bilinen Sınırlama / Bilinen Eksik: Resmî tatiller (bayramlar vb.) hesaba katılmaz, sadece hafta sonları hariç tutulur.
  def working_days_count
    return 0 if start_date.blank? || end_date.blank? || start_date > end_date

    count = 0
    current = start_date
    while current <= end_date
      # In Ruby: wday 0 is Sunday, 6 is Saturday
      count += 1 unless current.saturday? || current.sunday?
      current += 1.day
    end
    count
  end

  # SLA Calculation
  # SLA kuralı: Yalnızca bekleyen ('pending') talepler için geçerlidir ve oluşturulmasından itibaren 48 saat dolunca tetiklenir.
  def overdue?
    return false unless status == "pending"
    return false if created_at.blank?

    created_at <= SLA_LIMIT.ago
  end

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def decided?
    approved? || rejected?
  end

  # State Transition: Approve
  def approve!(manager)
    raise AuthorizationError, "Yalnızca yöneticiler izin onaylayabilir." unless manager&.manager?
    raise AuthorizationError, "Çalışan kendi izin talebini onaylayamaz." if manager.id == user_id
    raise StateTransitionError, "Yalnızca beklemedeki talepler onaylanabilir (Mevcut durum: #{status})." unless pending?

    days = working_days_count
    raise InsufficientBalanceError, "İzin süresi 0 iş günüdür." if days <= 0

    transaction do
      # Deduct balance if applicable
      if leave_type.in?(%w[annual sick])
        user.deduct_balance!(leave_type, days)
      end

      update!(
        status: "approved",
        decided_by: manager,
        decided_at: Time.current
      )
    end
    true
  end

  # State Transition: Reject
  def reject!(manager, reason = nil)
    raise AuthorizationError, "Yalnızca yöneticiler izin talebini reddedebilir." unless manager&.manager?
    raise AuthorizationError, "Çalışan kendi izin talebini reddedemez." if manager.id == user_id
    raise StateTransitionError, "Yalnızca beklemedeki talepler reddedilebilir (Mevcut durum: #{status})." unless pending?

    transaction do
      update!(
        status: "rejected",
        decided_by: manager,
        decided_at: Time.current,
        rejection_reason: reason.presence
      )
    end
    true
  end

  # 100 Puanlık Özellik: Akıllı İzin Planlama Uyarısı (Team Conflict Detection)
  # Aynı departmandaki diğer çalışanların çakışan ONAYLANMIŞ izinlerini tespit eder.
  def conflicting_team_requests
    return LeaveRequest.none if user.blank? || start_date.blank? || end_date.blank?

    self.class.team_conflicts_for(user, start_date, end_date)
  end

  def self.team_conflicts_for(target_user, s_date, e_date)
    return none if target_user.blank? || s_date.blank? || e_date.blank?

    joins(:user)
      .where(users: { department: target_user.department })
      .where.not(user_id: target_user.id)
      .where(status: "approved")
      .where("leave_requests.start_date <= ? AND leave_requests.end_date >= ?", e_date, s_date)
  end

  private

  def validate_dates_order
    return if start_date.blank? || end_date.blank?

    if start_date > end_date
      errors.add(:end_date, "başlangıç tarihinden önce olamaz.")
    end

    if working_days_count <= 0 && start_date <= end_date
      errors.add(:base, "Seçilen tarih aralığında en az 1 iş günü bulunmalıdır (hafta sonları hariç tutulmaktadır).")
    end
  end

  def validate_no_overlapping_requests_for_user
    return if user.blank? || start_date.blank? || end_date.blank?

    existing = user.leave_requests
                   .where(status: %w[pending approved])
                   .where("start_date <= ? AND end_date >= ?", end_date, start_date)

    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      errors.add(:base, "Bu tarih aralığında zaten bekleyen veya onaylanmış bir izin talebiniz bulunmaktadır.")
    end
  end

  def validate_sufficient_balance
    return if user.blank? || leave_type.blank? || start_date.blank? || end_date.blank?
    return if start_date > end_date

    days = working_days_count
    current_balance = user.remaining_balance_for(leave_type)
    return if current_balance.nil? # e.g. unpaid leave

    if current_balance < days
      errors.add(:base, "Yetersiz izin bakiyesi: Bu talep #{days} iş günü gerektiriyor, mevcut bakiyeniz: #{current_balance} gün.")
    end
  end
end
