class LeaveReturnSummary < ApplicationRecord
  belongs_to :leave_request
  belongs_to :user

  validates :leave_request_id, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates :generated_at, presence: true

  # Ensure user matches leave_request.user
  validate :validate_user_matches_leave_request

  private

  def validate_user_matches_leave_request
    return unless leave_request && user
    if leave_request.user_id != user_id
      errors.add(:user_id, "Özet yalnızca izin sahibi çalışana ait olabilir.")
    end
  end
end
