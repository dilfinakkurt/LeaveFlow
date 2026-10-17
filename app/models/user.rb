class User < ApplicationRecord
  has_secure_password

  ROLES = %w[employee manager].freeze

  # Associations
  has_many :leave_requests, dependent: :destroy
  has_many :decided_requests, class_name: "LeaveRequest", foreign_key: "decided_by_id", dependent: :nullify
  belongs_to :manager, class_name: "User", optional: true
  has_many :subordinates, class_name: "User", foreign_key: "manager_id", dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :annual_leave_balance, numericality: { greater_than_or_equal_to: 0 }
  validates :sick_leave_balance, numericality: { greater_than_or_equal_to: 0 }

  before_validation :normalize_email

  def manager?
    role == "manager"
  end

  def employee?
    role == "employee"
  end

  def remaining_balance_for(leave_type)
    case leave_type.to_s
    when "annual"
      annual_leave_balance
    when "sick"
      sick_leave_balance
    when "unpaid"
      nil # Unlimited / no balance deduction
    else
      0
    end
  end

  def deduct_balance!(leave_type, days)
    case leave_type.to_s
    when "annual"
      new_balance = annual_leave_balance - days
      raise ArgumentError, "Yetersiz yıllık izin bakiyesi" if new_balance < 0
      update!(annual_leave_balance: new_balance)
    when "sick"
      new_balance = sick_leave_balance - days
      raise ArgumentError, "Yetersiz hastalık izni bakiyesi" if new_balance < 0
      update!(sick_leave_balance: new_balance)
    when "unpaid"
      true # No deduction for unpaid leave
    end
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
