class AiChatMessage < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :user
  belongs_to :leave_request, optional: true

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true

  scope :chronological, -> { order(created_at: :asc) }
  scope :recent_first, -> { order(created_at: :desc) }

  def user_message?
    role == "user"
  end

  def assistant_message?
    role == "assistant"
  end
end
